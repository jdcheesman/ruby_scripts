require_relative 'PLSQLProc'
require_relative 'LogError'
require_relative 'Call'
require_relative 'SessionThread'
require 'set'


class ProcParser
    DATE_SLICE = 0 # not used
    TIME_SLICE = 1
    LOG_LEVEL_SLICE = 2 # not used
    THREAD_SLICE = 3
    JAVA_ID_SLICE = 4
    PLSQL_SLICE = 5

    attr :filename
    attr_accessor :allprocs
    attr_accessor :errors
    attr_accessor :errorcount
    attr_accessor :nodename
    attr_accessor :calls
    attr_accessor :missing
    attr_accessor :date
    attr_accessor :finished_threads

    def initialize(directory, filename)
        directory = directory + "\\" if directory !~ /\\$/
        @filename = directory + filename
        @nodename = filename.sub(/\.log$/, "").chomp.strip
        @allprocs = Hash[]
        @errors = Array[]
        @errorcount = 0
        @calls = Hash[]
        @missing = Set.new
        @finished_threads = Hash[]
    end

    ########################################################
    #
    # Parse a log file to get elapsed times for PLSQL calls
    #
    # Example line:
    # 2013-01-24 09:23:15.552 [INFO] [AJPRequestHandler-ApplicationServerThread-24] es.uned.portal.gaia.matriculapas.portlet.EnvioCartasPortlet.renderBody===> ***INICIO DE EJECUCION --- EnvioCartasPortlet Pas***
    #
    # Assumptions:
    # * format of start and end of log messages for PLSQL calls
    # * Single day logs (in decade 2010-2019)
    # * thread identified by "AJPRequestHandler-ApplicationServerThread-"
    ########################################################
    def parse()
        f = File.open(@filename, "r")
        inicioProc_StartTime = Hash[]
        plSqlData = Hash[]
        linecounter = 0
        previouserror = LogError.new("", "", "abc.def", 1)
        previous_line_time_rounded = ""
        last_date = "START"
        current_threads = Hash[]
        last_time_in_thread = Hash[]
        new_thread_cutoff = 4000
        absolute_thread_cutoff = 120000 # two minutes
        normalisedTime = 0
        f.each_line do|line|
            linecounter += 1
            if line =~ /^201[3..9]/ and line =~ /AJPRequestHandler-ApplicationServerThread-/
                lineData = line.split(' ', 6)
                @date = lineData[DATE_SLICE]
                current_thread_id = lineData[THREAD_SLICE]
                if !(last_date == "START") & !(@date == last_date)
                    printf("Log file spans various dates (only last date used in ouput): %s != %s\n", last_date, @date)
                end
                last_date = @date
                current_line_time_rounded = ProcParser.get_hour_minute(lineData[TIME_SLICE])
                call = get_current_call(current_line_time_rounded, previous_line_time_rounded, normalisedTime)
                previous_line_time_rounded = current_line_time_rounded
                normalisedTime = get_normalised_time(lineData[TIME_SLICE])

                time_since_last_call_in_thread = 0
                if current_threads[current_thread_id] != nil
                    time_since_last_call_in_thread = normalisedTime-last_time_in_thread[current_thread_id]
                end

                # # detect start of portlet:
                # if line.downcase =~ /portlet.*renderbody===>.*inicio.*render/ or
                #     line =~ /EnvioCartasPortlet.renderBody===> \*\*\*INICIO DE EJECUCION --- EnvioCartasPortlet Pas/ or
                #     last_time_in_thread[current_thread_id] == nil or
                #     (time_since_last_call_in_thread > new_thread_cutoff and !current_threads[current_thread_id].in_proc) or
                #     time_since_last_call_in_thread > absolute_thread_cutoff

                #     if current_threads[current_thread_id] == nil
                #         current_threads[current_thread_id] = SessionThread.new(lineData[JAVA_ID_SLICE], normalisedTime, lineData[TIME_SLICE])
                #     else
                #         if line !~ /\[ERROR\].*Portlet.renderBody/
                #             add_finished_thread(current_threads[current_thread_id])
                #         end
                #         current_threads[current_thread_id] = SessionThread.new(lineData[JAVA_ID_SLICE], normalisedTime, lineData[TIME_SLICE])
                #     end
                # end
                # # detect change of portlet:
                # if line =~ /\[INFO\].*Portlet.renderBody/ and
                #     lineData[JAVA_ID_SLICE].split('.')[-2] != current_threads[current_thread_id].id and
                #     current_threads[current_thread_id].id =~ /[a-z]Portlet/
                #     add_finished_thread(current_threads[current_thread_id])
                #     current_threads[current_thread_id] = SessionThread.new(lineData[JAVA_ID_SLICE], normalisedTime, lineData[TIME_SLICE])
                # end

                # last_time_in_thread[current_thread_id] = normalisedTime
                # if current_threads[current_thread_id] != nil
                #     current_threads[current_thread_id].update(normalisedTime, lineData[TIME_SLICE], lineData[JAVA_ID_SLICE], lineData[PLSQL_SLICE])
                # end

                # # detect end of portlet:
                # if line =~ /Portlet.renderBody.*Fin/ or
                #     line =~ /Portlet.renderBody===> ----->FIN RENDER/  or
                #     line =~ /\[ERROR\].*Portlet.renderBody/
                #     add_finished_thread(current_threads[current_thread_id])
                #     current_threads[current_thread_id] = SessionThread.new(lineData[JAVA_ID_SLICE], normalisedTime, lineData[TIME_SLICE])
                # end

                if line =~/\[ERROR\]/
                    le = LogError.new(lineData[TIME_SLICE], lineData[PLSQL_SLICE], lineData[JAVA_ID_SLICE], normalisedTime)
                    #puts line
                    if le.same?(previouserror)
                        @errors.pop
                        le.code = previouserror.code
                    else
                        @errorcount += 1
                    end
                    @errors << le
                    previouserror = le
                    call.add_error()
                end
                call.add_call()
                call.add_time(normalisedTime)



                # following logic assumes there are no overlapping PL/SQL calls in a given thread+method
                thread_java_id = current_thread_id + "#" + lineData[JAVA_ID_SLICE]
                if (lineData[PLSQL_SLICE].downcase =~ /inicio procedimiento/ or lineData[PLSQL_SLICE] =~ /\{call/ or lineData[PLSQL_SLICE] =~ /\{?=call/)
                    inicioProc_StartTime[thread_java_id] = normalisedTime
                    plSqlData[thread_java_id] = lineData[PLSQL_SLICE]
                    @missing.add(get_pl_sql_key(lineData, plSqlData, thread_java_id))
                    # current_threads[current_thread_id].in_proc = true
                    # @@missing_proc.each do | proc |
                    #     if line =~ /#{proc}/
                    #         # printf("Found missing proc: %s", line)
                    #         current_threads[current_thread_id].in_proc = false
                    #     end
                    # end
                elsif (lineData[PLSQL_SLICE].downcase =~ /fin procedimiento/)
                    # current_threads[current_thread_id].in_proc = false
                    if inicioProc_StartTime[thread_java_id] == nil
                        # experience shows following is never called, although is expected for transactions @ midnight
                        printf("%s missing start marker @ [%s]\n", lineData[JAVA_ID_SLICE], lineData[TIME_SLICE])
                    else
                        key = get_pl_sql_key(lineData, plSqlData, thread_java_id)
                        @missing.delete(key)
                        # log_pl_sql(lineData[JAVA_ID_SLICE], plSqlData[thread_java_id], (normalisedTime - inicioProc_StartTime[thread_java_id]), lineData[TIME_SLICE])
                        log_pl_sql(key, plSqlData[thread_java_id], (normalisedTime - inicioProc_StartTime[thread_java_id]), lineData[TIME_SLICE])
                    end
                end
                @calls[current_line_time_rounded] = call
            end
        end
        f.close

        # current_threads.each_key do  | live_thread_key |
        #     add_finished_thread(current_threads[live_thread_key])
        # end

        linecounter
    end

    def get_pl_sql_key(lineData, plSqlData, thread_java_id)
        lineData[JAVA_ID_SLICE] + "#" + PLSQLProc.get_proc_name(PLSQLProc.clean_up_plSqlData(plSqlData[thread_java_id]))
    end

    def get_normalised_time(string_time)
        # Expected: 09:23:15.552
        time = /[0]?(\d+):[0]?(\d+):[0]?(\d+)\.[0]?[0]?(\d+)/.match(string_time)
        hours = time[1].to_i
        minutes = time[2].to_i
        sec = time[3].to_i
        ms = time[4].to_i
        (hours * 60 * 60 * 1000) + (minutes * 60 * 1000) + (sec * 1000) + ms
    end

    def self.get_hour_minute(string_time)
        # Expected: 09:23:15.552
        time = /([0]?\d+):[0]?(\d+):[0]?(\d+)\.[0]?[0]?(\d+)/.match(string_time)
        hours = time[1]
        minutes = time[2].to_i
        if minutes < 15
            hours + ":00"
        elsif minutes < 30
            hours + ":15"
        elsif minutes < 45
            hours + ":30"
        else
            hours + ":45"
        end
    end


    def get_pl_sql(pl_sql_key)
        if @allprocs[pl_sql_key] == nil
            p = PLSQLProc.new(pl_sql_key)
        else
            p = @allprocs[pl_sql_key]
        end
        p
    end

    def log_pl_sql(pl_sql_key, plsql, endTime, time)
        # note thread id is NOT part of key for output data:
        p = get_pl_sql(pl_sql_key)
        p.add_call(endTime, plsql, time)
        @allprocs[pl_sql_key] = p
    end

    def get_current_call(current_line_time_rounded, previous_line_time_rounded, normalised_time)
        if current_line_time_rounded != previous_line_time_rounded
            call = Call.new(current_line_time_rounded, normalised_time)
        else
            call = @calls[current_line_time_rounded]
        end
    end

    def add_finished_thread(sessionThread)
        # printf("Finishing thread for id: %s\n", sessionThread.id)
        if @finished_threads[sessionThread.id] == nil
            @finished_threads[sessionThread.id] = Array[]
        end
        @finished_threads[sessionThread.id] << sessionThread
    end


    @@missing_proc = ["es.uned.portal.gaia.datospersonalesalumno.bd.sql.AlumnoDPDao.*puedeModificarDiscapacidad.*MATRICULAS.DOCUMENTO_VALIDO",
"es.uned.portal.gaia.datospersonalesalumno.bd.sql.AlumnoDPDao.*tieneMatriculaAsignaturaAsociada.*MATRICULAS.PK_REC_DATPER.existe_mat_conf_asig_exp",
"es.uned.portal.gaia.datospersonalesalumno.bd.sql.ComponenteFormularioDao.*obtenerTiposDocumento.*UNED.PK_LISTGENERALES.listado_tipos_docu_identif",
"es.uned.portal.gaia.datospersonalesalumno.bd.sql.ComponenteFormularioDao.*obtenerEstudiosTerminados.*UNED.PK_LISTGENERALES.listado_estudiosterm_alumno",
"es.uned.portal.gaia.datospersonalesalumno.bd.sql.ComponenteFormularioDao.*obtenerLugaresTrabajo.*UNED.PK_LISTGENERALES.listado_lugares_trabajo",
"es.uned.portal.gaia.datospersonalesalumno.bd.sql.ComponenteFormularioDao.*obtenerModalidadesIngreso.*UNED.PK_LISTGENERALES.modalidades_acceso_univ",
"es.uned.portal.gaia.datospersonalesalumno.bd.sql.AlumnoDPDao.*obtenerTiposVia.*UNED.PK_LISTGENERALES.listado_tipo_vias",
"es.uned.portal.gaia.datospersonalesalumno.bd.sql.ComponenteFormularioDao.*obtenerOcupacionesProfesionales.*UNED.PK_LISTGENERALES.listado_trabajos_padres",
"es.uned.portal.gaia.datospersonalesalumno.bd.sql.AlumnoDPDao.*modificarAlumno.*MATRICULAS.Modifgen_datper_ce",
"es.uned.portal.gaia.datospersonalesalumno.bd.sql.AlumnoDPDao.*insertarAlumno.*MATRICULAS.Modifgen_datper_ce",
"es.uned.portal.gaia.datospersonalesalumno.bd.sql.AlumnoDPDao.*insertarDatosComplementarios.*MATRICULAS.PK_DATPER_COMPLE.ACTUALIZAR_DATPER_COMPLE",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*ListadoSolicitud.*POSGRADO_PRO.PK_REC_SOLICITUDES.BuscaSolByDNI",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*listadoTipoSolicitudes.*POSGRADO_PRO.PK_REC_SOLICITUDES.listado_tipos_sol_activos",
"es.uned.portal.gaia.certificadosalumno.bd.sql.ComponenteFormularioDao.*getAtributosBuscador.*UNED.PK_LISTGENERALES.listado_atributos_tit",
"es.uned.portal.gaia.matriculapas.bd.sql.ComponenteFormularioDao.*getMatricula.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.datos_gen_mat",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*getNombrePrograma.*UNED.PK_LISTGENERALES.obt_nom_programa",
"es.uned.portal.gaia.matriculapas.bd.sql.AsignaturaDao.*getListaAsignaturasAsociadas.*POSGRADO_PRO.PK_GPOS_REC_ASIGNATURAS.listado_asig_mat",
"es.uned.portal.gaia.matriculapas.bd.sql.CreditosDAO.*creditosReconocidosMatricula.*POSGRADO_PRO.PK_GPOS_REC_CONJUNTO_CRED.lista_cc_mat",
"es.uned.portal.gaia.matriculapas.bd.sql.ComponenteFormularioDao.*getOpDomiciliacion.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.obtener_op_dom",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*modificarMatriculaCartas.*POSGRADO_PRO.PK_GPOS_MATRICULA.modificar_gpos_matricula",
"es.uned.portal.gaia.matriculapas.bd.sql.PagosDao.*actualizarRecibos.*POSGRADO_PRO.PK_GPOS_MAT_PAGOS.actualizar_recibos_mat",
"es.uned.portal.gaia.matriculapas.bd.sql.ReparosDao.*listadoReparosMat.*MATRICULAS.PK_REC_DATPER_TIT.listado_reparos_mat",
"es.uned.portal.gaia.matriculapas.bd.sql.CartaDao.*obtenerLiteralEstadoDocumento.*MATRICULAS.PK_REC_DATPER_TIT.literal_estado_docu",
"es.uned.portal.gaia.matriculapas.bd.sql.PagosDao.*literalBanco.*UNED.OBTENER_SELECCION_BANCO",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*obtenerFecha.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.obtener_fecha",
"es.uned.portal.gaia.matriculapas.portlet.EnvioCartasPortlet.*permisoAMA.*POSGRADO_PRO.PK_ACCESOS.permiso_entidades_mat",
"es.uned.portal.gaia.matriculapas.bd.sql.CartaDao.*requerimientosPago.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.requerimientos_no_documentales",
"es.uned.portal.gaia.matriculapas.bd.sql.CartaDao.*actualizarPeticionesPago.*MATRICULAS.PK_PETICIONES.Actualizar_peticiones",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*listadosCentrosAsociados.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.listado_centros_asociados",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*listadoClaseMatriculas.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.listado_clase_mat",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*requiereSolTitAcceso.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.req_sol_tit_acceso",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*modificarEstadoMatricula.*POSGRADO_PRO.PK_GPOS_MATRICULA.modificar_gpos_matricula",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*getClaseMatriculaAsociadaXSolicitud.*POSGRADO_PRO.PK_REC_SOLICITUDES.clase_mat_asoc_sol",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*getListadoTiposInclusionXSolicitud.*POSGRADO_PRO.PK_REC_SOLICITUDES.listado_inclusiones_sol",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*ListadoClasesMatricula.*POSGRADO_PRO.PK_REC_SOLICITUDES.listado_clases_mat_sol",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*getListadoTiposInclusion.*POSGRADO_PRO.PK_REC_SOLICITUDES.listado_tipos_inclusion",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*getListadoValoresTipoInclusion.*POSGRADO_PRO.PK_REC_SOLICITUDES.listado_tipos_inclusion",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*trasladoNecesario.*POSGRADO_PRO.PK_REC_SOLICITUDES.sol_tipo_traslado",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*puedeMatricularse.*UNED.PK_LISTGENERALES.puede_matricularse",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*centroAsociadoValido.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.centros_asociado_valido",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*modificarAlumno.*MATRICULAS.Modifgen_datper_ce",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*modificarMatricula.*POSGRADO_PRO.PK_GPOS_MATRICULA.modificar_gpos_matricula",
"es.uned.portal.gaia.matriculapas.bd.sql.TitulacionAccesoDao.*getListaModosAcceso.*UNED.Pk_ListGenerales.lista_modos_acceso",
"es.uned.portal.gaia.matriculapas.bd.sql.TitulacionAccesoDao.*getListaCamposMostrados.*MATRICULAS.PK_REC_DATPER_TIT.lista_campos_mostrado_titul",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*getListaTitulacionesAlumno.*MATRICULAS.PK_REC_DATPER_TIT.listado_titulaciones_alumno",
"es.uned.portal.gaia.datospersonalespas.bd.sql.ComponenteFormularioDao.*getNotasAlf.*UNED.PK_LISTGENERALES.listado_notas_alf",
"es.uned.portal.gaia.datospersonalespas.bd.sql.ComponenteFormularioDao.*getProgramasEstudioMH.*UNED.PK_LISTGENERALES.listado_prog_estudios_dmh",
"es.uned.portal.gaia.datospersonalespas.bd.sql.ComponenteFormularioDao.*getTiposCertificado.*UNED.PK_LISTGENERALES.listado_tipos_cert_titul",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*getConvocatorias.*UNED.PK_LISTGENERALES.listado_convocatoriasexamen",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*getCentroEmisor.*UNED.PK_LISTGENERALES.listado_centros_emisores",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*getIdMatriculaDescMH.*MATRICULAS.PK_REC_DATPER_TIT.lis_matriculas_para_descmh",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*getListaViasEstudio.*UNED.PK_LISTGENERALES.listado_vias_estudio_tit_acc",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*getListaCamposMostrados.*MATRICULAS.PK_REC_DATPER_TIT.lista_campos_mostrado_titul",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*admiteTresDecimales.*UNED.PK_LISTGENERALES.TITULACION_TRES_DECIMALES",
"es.uned.portal.gaia.matriculapas.bd.sql.AsignaturasExpedienteDao.*creditosReconocidos.*POSGRADO_PRO.PK_GPOS_REC_CONJUNTO_CRED.lista_cc_reconocibles",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*insertarModificarBorrarTitulacionAlumno.*MATRICULAS.PK_DATPER_TIT.Actualizar_datper_titulaciones",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*getListaModosAcceso.*UNED.Pk_ListGenerales.lista_modos_acceso",
"es.uned.portal.gaia.datospersonalespas.bd.sql.DocumentoDao.*complementarDocInfoTipo.*UNED.PK_LISTGENERALES.datos_documento",
"es.uned.portal.gaia.datospersonalespas.bd.sql.DocumentoDao.*getListaEstadosDocumento.*UNED.PK_LISTGENERALES.listado_estados_docus",
"es.uned.portal.gaia.datospersonalespas.bd.sql.DocumentoDao.*getListaDatosVinculadosDoc.*MATRICULAS.PK_REC_DATPER_TIT.listar_datos_vinculados_doc",
"es.uned.portal.gaia.datospersonalespas.bd.sql.DocumentoDao.*insertarModificarEliminarDocumentoAlumno.*MATRICULAS.PK_DATPER_TIT.Actualizar_datper_documentos",
"es.uned.portal.gaia.matriculapas.bd.sql.AsignaturasExpedienteDao.*convalidarCreditos.*POSGRADO_PRO.PK_GPOS_CONJUNTO_CRED.Actualizar_conjunto_creditos",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*getTitulacion.*UNED.PK_LISTGENERALES.datos_titulacion",
"es.uned.portal.gaia.matriculaalumno.bd.sql.AsignaturaDao.*getListaAsignaturasAsociadas.*POSGRADO_PRO.PK_GPOS_REC_ASIGNATURAS.listado_asig_mat",
"es.uned.portal.gaia.matriculaalumno.bd.sql.MatriculaDao.*obtenerFecha.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.obtener_fecha",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*actualizarDatosViaAlumno.*POSGRADO_PRO.PK_GPOS_DATPER.actualizar_datpervia",
"es.uned.portal.gaia.datospersonalespas.bd.sql.ComponenteFormularioDao.*getAtributosBuscador.*UNED.PK_LISTGENERALES.listado_atributos_tit",
"es.uned.portal.gaia.matriculapas.bd.sql.TitulacionAccesoDao.*insertarModificarBorrarTitulacionAlumno.*MATRICULAS.PK_DATPER_TIT.Actualizar_datper_titulaciones",
"es.uned.portal.gaia.matriculapas.bd.sql.CreditosDAO.*creditosReconocidos.*POSGRADO_PRO.PK_GPOS_REC_CONJUNTO_CRED.lista_cc_reconocibles",
"es.uned.portal.gaia.matriculapas.bd.sql.AsignaturasExpedienteDao.*creditosReconocidos.*POSGRADO_PRO.PK_AUX_CLIENTE.lista_cc_reconoc_equiv",
"es.uned.portal.gaia.matriculapas.bd.sql.AsignaturaDao.*actualizarAsignatura.*POSGRADO_PRO.PK_GPOS_ASIGNATURAS.*actualizar_gpos_asignaturas",
"es.uned.portal.gaia.matriculapas.bd.sql.TitulacionAccesoDao.*getTitulacion.*UNED.PK_LISTGENERALES.datos_titulacion",
"es.uned.portal.gaia.matriculapas.bd.sql.MatriculaDao.*existeExpedienteAlumno.*POSGRADO_PRO.PK_FUNCAUX_SOL.EXISTE_EXPEDIENTE_ALUMNO",
"es.uned.portal.gaia.matriculapas.bd.sql.CreditosDAO.*borrarConjuntoCreditos.*POSGRADO_PRO.PK_GPOS_CONJUNTO_CRED.Borrar_conjunto_creditos",
"es.uned.portal.gaia.matriculapas.bd.sql.AsignaturaDao.*getListadoAsignaturasOferAnuladas.*POSGRADO_PRO.PK_GPOS_REC_ASIGNATURAS.Asignaturas_ofer_anuladas",
"es.uned.portal.gaia.datospersonalespas.bd.sql.DocumentoDao.*getListaDocumentosAlumno.*MATRICULAS.PK_REC_DATPER_TIT.listado_documentos_alumno",
"es.uned.portal.gaia.datospersonalespas.bd.sql.DocumentoDao.*getDocumento.*MATRICULAS.PK_REC_DATPER_TIT.listado_documentos_alumno",
"es.uned.portal.gaia.datospersonalespas.bd.sql.TitulacionDao.*getNomTitPagina.*UNED.Pk_ListGenerales.lista_modos_acceso",
"es.uned.portal.gaia.matriculapas.bd.sql.CreditosDAO.*actualizarConjuntoCreditos.*POSGRADO_PRO.PK_GPOS_CONJUNTO_CRED.Actualizar_conjunto_creditos",
"es.uned.portal.gaia.matriculapas.bd.sql.CreditosDAO.*actualizarCalif_RC_CC.*POSGRADO_PRO.PK_GPOS_CALIF_RC.Actualizar_calif_rc_cc",
"es.uned.portal.gaia.certificadospas.bd.sql.ComponenteFormularioDao.*getAtributosBuscador.*UNED.PK_LISTGENERALES.listado_atributos_tit",
"es.uned.portal.gaia.certificadospas.bd.sql.ComponenteFormularioDao.*getListaTitulacionesUned.*UNED.PK_LISTGENERALES.listado_titulaciones",
"es.uned.portal.gaia.matriculapas.bd.sql.PagosDao.*desasignarPago.*POSGRADO_PRO.PK_GPOS_MAT_PAGOS.*Desasignar_pago",
"es.uned.portal.gaia.matriculapas.bd.sql.PagosDao.*unificarRecibos.*POSGRADO_PRO.PK_GPOS_MAT_PAGOS.unificar_recibos",
"es.uned.portal.gaia.datospersonalespas.bd.sql.ComponenteFormularioDao.*getListaTitulacionesUned.*UNED.PK_LISTGENERALES.listado_titulaciones",
"es.uned.portal.gaia.matriculaalumno.bd.sql.CreditosDAO.*creditosReconocidosMatricula.*POSGRADO_PRO.PK_GPOS_REC_CONJUNTO_CRED.lista_cc_mat",
"es.uned.portal.gaia.matriculaalumno.bd.sql.MatriculaDao.*modificarMatriculaCartas.*POSGRADO_PRO.PK_GPOS_MATRICULA.modificar_gpos_matricula",
"es.uned.portal.gaia.datospersonalespas.bd.sql.DocumentoDao.*getListaDocumentosUned.*UNED.PK_LISTGENERALES.listado_documentos",
"es.uned.portal.gaia.datospersonalespas.bd.sql.AlumnoDPDao.*comprobarDatosMinisterio.*MATRICULAS.DOCUMENTO_VALIDO",
"es.uned.portal.gaia.datospersonalespas.bd.sql.AlumnoDPDao.*modificarAlumno.*MATRICULAS.Modifgen_datper_ce",
"es.uned.portal.gaia.reconocimientocreditos.bd.sql.IncorporacionDerechosEstudianteDao.*actualizarTitulacion.*MATRICULAS.PK_DATPER_TIT.Actualizar_datper_titulaciones",
"es.uned.portal.gaia.reconocimientocreditos.bd.sql.IncorporacionDerechosEstudianteDao.*a.adirDocumentos.*MATRICULAS.PK_DATPER_TIT.Actualizar_datper_documentos",
"es.uned.portal.gaia.matriculapas.bd.sql.PagosDao.*modificarRecibo.*POSGRADO_PRO.PK_GPOS_MAT_PAGOS.*modificar_recibo",
"es.uned.portal.gaia.matriculaalumno.bd.sql.PagosDao.*unificarRecibos.*POSGRADO_PRO.PK_GPOS_MAT_PAGOS.unificar_recibos",
"es.uned.portal.gaia.datospersonalesalumno.bd.sql.AlumnoDPDao.*modificarAlumnoDatosMinisterio.*MATRICULAS.PK_IMPORTADORES.importar_datos_dni_min",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*listadoProgramasSol.*POSGRADO_PRO.PK_REC_SOLICITUDES.lista_prog_by_tiposol",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*puedeRealizarSol.*POSGRADO_PRO.PK_REC_SOLICITUDES.puede_realizar_sol",
"es.uned.portal.gaia.datospersonalespas.bd.sql.AlumnoDPDao.*getAlumnosxNombreApellidos.*MATRICULAS.PK_REC_DATPER.datosper_by_apellidosnombre",
"es.uned.portal.gaia.gestiondomicilios.bd.sql.GestionDomDAO.*obtenerDatosUsuario.*MATRICULAS.PK_REC_DATPER_DOMICILIOS.obtener_datos_personales",
"es.uned.portal.gaia.matriculaalumno.bd.sql.ReparosDao.*derechoAExamen.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.examen_extraordinario",
"es.uned.portal.gaia.reconocimientocreditos.bd.sql.IncorporacionDerechosEstudianteDao.*generarMatriculaManual.*UNED.PK_RC.equivalencia_excepcional",
"es.uned.portal.gaia.matriculaalumno.bd.sql.DiscapacidadDao.*puedeModificarDiscapacidad.*MATRICULAS.DOCUMENTO_VALIDO",
"es.uned.portal.gaia.matriculapas.bd.sql.BuscadorMatriculasDao.*listaMatriculasPuedeConf.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.listado_mat_puede_conf",
"es.uned.portal.gaia.matriculapas.bd.sql.PagosDao.*datosPagoTarjeta.*POSGRADO_PRO.PK_GPOS_MAT_PAGOS.generar_datos_pago_tarjeta",
"es.uned.portal.gaia.datospersonalespas.bd.sql.AlumnoDPDao.*insertarAlumno.*MATRICULAS.Modifgen_datper_ce",
"es.uned.portal.gaia.matriculapas.bd.sql.PagosDao.*listadoPagadosNoAsociados.*POSGRADO_PRO.PK_GPOS_REC_MATRICULA.listado_pagos_pag_noasociados",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*listadoMatriculaSolicitud.*POSGRADO_PRO.PK_REC_SOLICITUDES.obt_lista_sol_procesos",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*listadoUniversidades.*POSGRADO_PRO.PK_REC_SOLICITUDES.listado_univ_traslado",
"es.uned.portal.gaia.certificadospas.bd.sql.SolicitudDao.*modificarSolicitud.*POSGRADO_PRO.PK_AC_SOLICITUDES.modificar_solicitud",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*insertarSolicitud.*POSGRADO_PRO.PK_AC_SOLICITUDES.Insertar_solicitud",
"es.uned.portal.gaia.certificadosalumno.bd.sql.PagosDao.*actualizarReciboSol.*POSGRADO_PRO.PK_AC_SOL_PAGOS.actualizar_recibos_sol",
"es.uned.portal.gaia.certificadosalumno.bd.sql.PagosDao.*obtenerImporte.*POSGRADO_PRO.PK_REC_SOLICITUDES.obtener_imp_tot",
"es.uned.portal.gaia.certificadosalumno.bd.sql.PagosDao.*listadoRecNoUnif.*POSGRADO_PRO.PK_REC_SOLICITUDES.listado_rec_pag_nounif",
"es.uned.portal.gaia.certificadosalumno.bd.sql.PagosDao.*obtenerCurso.*POSGRADO_PRO.PK_FUNCAUX_SOL.cursosol",
"es.uned.portal.gaia.matriculapas.bd.sql.PagosDao.*conciliarRecibo.*POSGRADO_PRO.PK_GPOS_MAT_PAGOS.*Conciliar_recibo",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*ListadoCentrosTraslado.*POSGRADO_PRO.PK_REC_SOLICITUDES.listado_centros_traslado",
"es.uned.portal.gaia.certificadosalumno.bd.sql.ComponenteFormularioDao.*getListaTitulacionesUned.*UNED.PK_LISTGENERALES.listado_titulaciones",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*ListadoDocumentosReqSol.*POSGRADO_PRO.PK_REC_SOLICITUDES.listado_docu_req_sol",
"es.uned.portal.gaia.certificadosalumno.bd.sql.DocumentosDao.*direccionEnvioDoc.*UNED.PK_LISTGENERALES.dirapc_fac",
"es.uned.portal.gaia.certificadosalumno.bd.sql.PagosDao.*obtenerLiteralBanco.*UNED.OBTENER_SELECCION_BANCO",
"es.uned.portal.gaia.certificadospas.bd.sql.ListadoPagosDAO.*obtenerLiteralBanco.*UNED.OBTENER_SELECCION_BANCO",
"es.uned.portal.gaia.certificadospas.bd.sql.ListadoPagosDAO.*obtenerCurso.*POSGRADO_PRO.PK_FUNCAUX_SOL.cursosol",
"es.uned.portal.gaia.certificadospas.bd.sql.PagosDao.*listadoPagadosNoAsociados.*POSGRADO_PRO.PK_REC_SOLICITUDES.*listado_pagos_pag_noasociados",
"es.uned.portal.gaia.certificadospas.bd.sql.PagosDao.*listadoNoPagadosAsociados.*POSGRADO_PRO.PK_REC_SOLICITUDES.*listado_pagos_pend_asociados",
"es.uned.portal.gaia.certificadosalumno.bd.sql.SolicitudDao.*modificarSolicitud.*POSGRADO_PRO.PK_AC_SOLICITUDES.modificar_solicitud",
"es.uned.portal.gaia.matriculapas.bd.sql.AsignaturasExpedienteDao.*getAsignaturasConvalidadas.*POSGRADO_PRO.PK_GPOS_ASIGNATURAS.actualizar_gpos_asignaturas",
"es.uned.portal.gaia.certificadospas.bd.sql.SolicitudDao.*lanzarBuscadorGlobal.*POSGRADO_PRO.PK_BUSCADOR_SOL.BuscadorGlobal"]

end