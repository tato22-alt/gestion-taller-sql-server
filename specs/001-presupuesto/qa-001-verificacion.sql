-- QA 001 — Presupuesto · verificación repetible
--
-- Spec: specs/001-presupuesto/spec.md · Plan: plan.md · Hallazgos: qa-hallazgos.md
--
-- POR QUÉ ES UNA SOLA FUNCIÓN Y NO UNA LISTA DE CONSULTAS:
-- el editor SQL de Supabase sólo muestra el resultado de la última sentencia de un
-- bloque. Verificar con varias sentencias sueltas esconde las fallas de todas menos la
-- última — así se dieron por buenas varias verificaciones de T001-T010 que en realidad
-- nadie vio. Acá todo el QA es UNA query, y devuelve una fila por verificación.
--
-- CÓMO SE USA: pegar este archivo entero y ejecutar. La última sentencia es el SELECT,
-- así que lo que se ve es la matriz completa.
--
-- QUÉ ESCRIBE: crea y borra sus propias filas, marcadas 'ZZQA%' y con
-- numero_presupuesto entre 99990000 y 99999999 (fuera del rango real, que arranca en
-- 16000). Limpia al entrar y al salir. Las pruebas que esperan un rechazo van dentro de
-- un bloque con EXCEPTION, así que se deshacen solas.
--
-- ESTADOS: PASA · FALLA · ABIERTO (hallazgo conocido, esperando decisión del dueño).

create or replace function fn_qa_001_presupuesto()
returns table (
  nro          int,
  bloque       text,
  ref          text,
  que_verifica text,
  estado       text,
  obs          text
)
language plpgsql
as $fn$
declare
  v_int   integer;
  v_bool  boolean;
  v_num   numeric;
  v_txt   text;
  v_arr   text[];
  v_cli   integer;
  v_veh   integer;
  v_tra   integer;
begin
  -- ---------------- limpieza previa ----------------
  delete from trabajos  where numero_presupuesto between 99990000 and 99999999;
  delete from trabajos  where txt_cliente like 'ZZQA%';
  delete from vehiculos where patente like 'ZZQA%';
  delete from clientes  where nombre  like 'ZZQA%';

  nro := 0;

  -- =====================================================================
  bloque := 'estructura';
  -- =====================================================================

  nro := nro + 1; ref := 'plan/esquema'; que_verifica := 'Existen las cuatro tablas';
  select count(*) into v_int from information_schema.tables
   where table_schema='public' and table_name in ('clientes','vehiculos','trabajos','trabajo_items');
  estado := case when v_int=4 then 'PASA' else 'FALLA' end;
  obs := v_int || ' de 4';
  return next;

  nro := nro + 1; ref := 'T009'; que_verifica := 'Existe la vista vw_presupuestos';
  select count(*) into v_int from information_schema.views
   where table_schema='public' and table_name='vw_presupuestos';
  estado := case when v_int=1 then 'PASA' else 'FALLA' end;
  obs := case when v_int=1 then 'presente' else 'no existe' end;
  return next;

  nro := nro + 1; ref := 'D8 / T007'; que_verifica := 'RLS habilitado en las cuatro tablas';
  select count(*) into v_int from pg_class
   where relnamespace='public'::regnamespace
     and relname in ('clientes','vehiculos','trabajos','trabajo_items')
     and relrowsecurity;
  estado := case when v_int=4 then 'PASA' else 'FALLA' end;
  obs := v_int || ' de 4 con RLS';
  return next;

  nro := nro + 1; ref := 'D8 / T007'; que_verifica := 'Cada tabla tiene política para authenticated';
  select count(distinct tablename) into v_int from pg_policies
   where schemaname='public'
     and tablename in ('clientes','vehiculos','trabajos','trabajo_items')
     and 'authenticated' = any(roles);
  estado := case when v_int=4 then 'PASA' else 'FALLA' end;
  obs := v_int || ' de 4 con política';
  return next;

  nro := nro + 1; ref := 'D8 / T008'; que_verifica := 'anon sin ningún privilegio sobre las tablas';
  select bool_or(has_table_privilege('anon', t, p)) into v_bool
    from unnest(array['clientes','vehiculos','trabajos','trabajo_items']) t,
         unnest(array['select','insert','update','delete']) p;
  estado := case when coalesce(v_bool,false)=false then 'PASA' else 'FALLA' end;
  obs := case when coalesce(v_bool,false) then 'anon conserva algún privilegio' else 'sin privilegios' end;
  return next;

  nro := nro + 1; ref := 'D8 / T009'; que_verifica := 'anon sin privilegios sobre la vista';
  v_bool := has_table_privilege('anon','vw_presupuestos','select');
  estado := case when v_bool=false then 'PASA' else 'FALLA' end;
  obs := case when v_bool then 'anon puede seleccionar la vista' else 'sin privilegios' end;
  return next;

  nro := nro + 1; ref := 'D8 / T009'; que_verifica := 'authenticated con SELECT sobre la vista';
  v_bool := has_table_privilege('authenticated','vw_presupuestos','select');
  estado := case when v_bool then 'PASA' else 'FALLA' end;
  obs := case when v_bool then 'otorgado' else 'FALTA el grant: la app no va a poder leer' end;
  return next;

  nro := nro + 1; ref := 'D7 / T009'; que_verifica := 'La vista respeta RLS de quien consulta (security_invoker)';
  select coalesce(array_to_string(reloptions,','),'') into v_txt
    from pg_class where relname='vw_presupuestos' and relnamespace='public'::regnamespace;
  estado := case when v_txt like '%security_invoker=%true%' then 'PASA' else 'FALLA' end;
  obs := case when v_txt='' then 'sin reloptions' else v_txt end;
  return next;

  nro := nro + 1; ref := 'D1 / T005'; que_verifica := 'numero_presupuesto: índice único parcial';
  select indexdef into v_txt from pg_indexes
   where schemaname='public' and indexname='ux_trabajos_numero_presupuesto';
  estado := case when v_txt ilike '%unique%' and v_txt ilike '%where%' then 'PASA' else 'FALLA' end;
  obs := coalesce(left(v_txt,90),'no existe el índice');
  return next;

  nro := nro + 1; ref := 'D3 / T003'; que_verifica := 'patente_norm: índice único';
  select indexdef into v_txt from pg_indexes
   where schemaname='public' and indexname='ux_vehiculos_patente_norm';
  estado := case when v_txt ilike '%unique%' then 'PASA' else 'FALLA' end;
  obs := coalesce(left(v_txt,90),'no existe el índice');
  return next;

  nro := nro + 1; ref := 'principio VI'; que_verifica := 'Cero triggers sobre las cuatro tablas';
  select count(*) into v_int from pg_trigger tg
    join pg_class c on c.oid=tg.tgrelid
   where not tg.tgisinternal
     and c.relnamespace='public'::regnamespace
     and c.relname in ('clientes','vehiculos','trabajos','trabajo_items');
  estado := case when v_int=0 then 'PASA' else 'FALLA' end;
  obs := v_int || ' triggers (ningún automatismo debe escribir)';
  return next;

  nro := nro + 1; ref := 'principio II / D2'; que_verifica := 'Ningún total almacenado en trabajos';
  select count(*) into v_int from information_schema.columns
   where table_schema='public' and table_name='trabajos'
     and column_name in ('monto_total','subtotal_repuestos','subtotal_conceptos','total');
  estado := case when v_int=0 then 'PASA' else 'FALLA' end;
  obs := case when v_int=0 then 'los totales sólo viven en la vista' else v_int || ' columnas de total' end;
  return next;

  nro := nro + 1; ref := 'principio I'; que_verifica := 'Ninguna columna de estado financiero/documental/siniestro';
  select count(*) into v_int from information_schema.columns
   where table_schema='public'
     and table_name in ('clientes','vehiculos','trabajos','trabajo_items')
     and (column_name ~ 'estado' or column_name ~ 'cobrad' or column_name ~ 'siniestro'
          or column_name ~ 'documentacion');
  estado := case when v_int=0 then 'PASA' else 'FALLA' end;
  obs := case when v_int=0 then 'ninguna' else v_int || ' columnas prohibidas' end;
  return next;

  -- =====================================================================
  bloque := 'registro';
  -- =====================================================================

  nro := nro + 1; ref := 'RF-013'; que_verifica := 'Cliente sólo con nombre: entra';
  begin
    insert into clientes (nombre) values ('ZZQA Cliente Minimo') returning id_cliente into v_cli;
    estado := 'PASA'; obs := 'id_cliente=' || v_cli;
  exception when others then
    estado := 'FALLA'; obs := sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'RF-013'; que_verifica := 'Cliente con nombre vacío: rechazado';
  begin
    insert into clientes (nombre) values ('   ');
    estado := 'FALLA'; obs := 'entró un cliente sin nombre real';
  exception when check_violation then
    estado := 'PASA'; obs := 'check_violation, como corresponde';
  when others then
    estado := 'FALLA'; obs := 'error inesperado: ' || sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'RF-008 / RF-014'; que_verifica := 'Trabajo sin cliente, vehículo, fecha ni origen: entra';
  begin
    insert into trabajos (origen_carga) values ('manual') returning id_trabajo into v_tra;
    select (id_cliente is null and id_vehiculo is null and fecha_presupuesto is null
            and origen is null and no_concretado = false and monto_mano_obra = 0)
      into v_bool from trabajos where id_trabajo = v_tra;
    estado := case when v_bool then 'PASA' else 'FALLA' end;
    obs := case when v_bool then 'nace vacío, con defaults correctos' else 'defaults inesperados' end;
    delete from trabajos where id_trabajo = v_tra;
  exception when others then
    estado := 'FALLA'; obs := sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'D3 / RF-011'; que_verifica := 'Patentes equivalentes colisionan (aa 123-bb = AA123BB)';
  begin
    insert into vehiculos (patente) values ('ZZQA 12-3');
    insert into vehiculos (patente) values ('zzqa123');
    estado := 'FALLA'; obs := 'entraron las dos: el vehículo se puede duplicar';
  exception when unique_violation then
    estado := 'PASA'; obs := 'unique_violation sobre patente_norm';
  when others then
    estado := 'FALLA'; obs := 'error inesperado: ' || sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'RF-022 / principio IV'; que_verifica := 'Patente con formato inválido: se guarda igual';
  begin
    insert into vehiculos (patente) values ('ZZQA-RARA-9') returning id_vehiculo into v_veh;
    estado := 'PASA'; obs := 'el esquema no impide registrar la realidad';
    delete from vehiculos where id_vehiculo = v_veh;
  exception when others then
    estado := 'FALLA'; obs := 'la base bloqueó una patente rara: ' || sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'RF-022'; que_verifica := 'Valida los dos formatos vigentes (AAR222 y AA000AA)';
  v_bool := fn_es_formato_patente_valido('AAR222') and fn_es_formato_patente_valido('AA000AA');
  estado := case when v_bool then 'PASA' else 'FALLA' end;
  obs := 'AAR222=' || fn_es_formato_patente_valido('AAR222') || ' AA000AA=' || fn_es_formato_patente_valido('AA000AA');
  return next;

  nro := nro + 1; ref := 'RF-022'; que_verifica := 'Rechaza lo que no es patente';
  v_bool := fn_es_formato_patente_valido('X1') or fn_es_formato_patente_valido('') or fn_es_formato_patente_valido('AAAA1111');
  estado := case when v_bool=false then 'PASA' else 'FALLA' end;
  obs := case when v_bool then 'aceptó basura' else 'rechaza X1, vacío y AAAA1111' end;
  return next;

  nro := nro + 1; ref := 'RF-001'; que_verifica := 'Número menor a 16000: rechazado';
  begin
    insert into trabajos (numero_presupuesto, origen_carga) values (15999,'manual');
    estado := 'FALLA'; obs := 'entró un número fuera de la serie';
  exception when check_violation then
    estado := 'PASA'; obs := 'check_violation, la serie arranca en 16000';
  when others then
    estado := 'FALLA'; obs := 'error inesperado: ' || sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'RF-020'; que_verifica := 'Dos trabajos con el mismo número: rechazado';
  begin
    insert into trabajos (numero_presupuesto, origen_carga) values (99990001,'manual');
    insert into trabajos (numero_presupuesto, origen_carga) values (99990001,'manual');
    estado := 'FALLA'; obs := 'dos presupuestos quedaron con el mismo número';
  exception when unique_violation then
    estado := 'PASA'; obs := 'unique_violation sobre numero_presupuesto';
  when others then
    estado := 'FALLA'; obs := 'error inesperado: ' || sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'D1'; que_verifica := 'Dos trabajos SIN número conviven';
  begin
    insert into trabajos (origen_carga, txt_cliente) values ('manual','ZZQA sin numero A');
    insert into trabajos (origen_carga, txt_cliente) values ('manual','ZZQA sin numero B');
    estado := 'PASA'; obs := 'el índice parcial no bloquea los nulos';
    delete from trabajos where txt_cliente like 'ZZQA sin numero%';
  exception when others then
    estado := 'FALLA'; obs := 'un trabajo sin presupuesto previo no puede entrar: ' || sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'RF-014'; que_verifica := 'origen fuera de dominio: rechazado';
  begin
    insert into trabajos (origen_carga, origen) values ('manual','loquesea');
    estado := 'FALLA'; obs := 'entró un origen inventado';
  exception when check_violation then
    estado := 'PASA'; obs := 'check_violation: sólo particular/siniestro o nulo';
  when others then
    estado := 'FALLA'; obs := 'error inesperado: ' || sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'plan/trabajos'; que_verifica := 'origen_carga fuera de dominio: rechazado';
  begin
    insert into trabajos (origen_carga) values ('a_mano_alzada');
    estado := 'FALLA'; obs := 'entró un origen_carga inventado';
  exception when check_violation then
    estado := 'PASA'; obs := 'check_violation, dominio cerrado';
  when others then
    estado := 'FALLA'; obs := 'error inesperado: ' || sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'T006 / RF-006'; que_verifica := 'Los conceptos vuelven en el orden de carga';
  begin
    insert into trabajos (origen_carga, txt_cliente) values ('manual','ZZQA orden')
      returning id_trabajo into v_tra;
    insert into trabajo_items (id_trabajo, orden, detalle, importe) values
      (v_tra, 2, 'tercero', 300), (v_tra, 0, 'primero', 100), (v_tra, 1, 'segundo', 200);
    select array_agg(ti.detalle order by ti.orden) into v_arr
      from trabajo_items ti where ti.id_trabajo = v_tra;
    estado := case when v_arr = array['primero','segundo','tercero'] then 'PASA' else 'FALLA' end;
    obs := array_to_string(v_arr,' , ');
  exception when others then
    estado := 'FALLA'; obs := sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'T006'; que_verifica := 'Borrar el trabajo borra sus conceptos (cascada)';
  begin
    delete from trabajos where id_trabajo = v_tra;
    select count(*) into v_int from trabajo_items ti where ti.id_trabajo = v_tra;
    estado := case when v_int=0 then 'PASA' else 'FALLA' end;
    obs := v_int || ' conceptos huérfanos';
  exception when others then
    estado := 'FALLA'; obs := sqlerrm;
  end;
  return next;

  -- =====================================================================
  bloque := 'derivación';
  -- =====================================================================

  nro := nro + 1; ref := 'D2 / RF-007'; que_verifica := 'monto_total = suma de conceptos + mano de obra';
  begin
    insert into trabajos (numero_presupuesto, origen_carga, txt_cliente, monto_mano_obra)
      values (99990010,'manual','ZZQA derivacion', 1000) returning id_trabajo into v_tra;
    insert into trabajo_items (id_trabajo, orden, detalle, importe) values
      (v_tra, 0, 'ZZQA repuesto', 8000), (v_tra, 1, 'ZZQA chapa y pintura', 15000);
    select vp.monto_total into v_num from vw_presupuestos vp where vp.id_trabajo = v_tra;
    estado := case when v_num = 24000 then 'PASA' else 'FALLA' end;
    obs := 'esperado 24000, obtenido ' || v_num;
  exception when others then
    estado := 'FALLA'; obs := sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'D2 / principio II'; que_verifica := 'El total se mueve al corregir un importe';
  begin
    update trabajo_items ti set importe = 9000
     where ti.id_trabajo = v_tra and ti.detalle = 'ZZQA repuesto';
    select vp.monto_total into v_num from vw_presupuestos vp where vp.id_trabajo = v_tra;
    estado := case when v_num = 25000 then 'PASA' else 'FALLA' end;
    obs := 'esperado 25000, obtenido ' || v_num || ' (nadie tocó ninguna columna de total)';
  exception when others then
    estado := 'FALLA'; obs := sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'RF-005 / RF-007'; que_verifica := 'Trabajo sin conceptos: total = mano de obra';
  begin
    insert into trabajos (numero_presupuesto, origen_carga, txt_cliente, monto_mano_obra)
      values (99990011,'manual','ZZQA sin items', 5000) returning id_trabajo into v_int;
    select vp.monto_total into v_num from vw_presupuestos vp where vp.id_trabajo = v_int;
    estado := case when v_num = 5000 then 'PASA' else 'FALLA' end;
    obs := 'esperado 5000, obtenido ' || v_num;
  exception when others then
    estado := 'FALLA'; obs := sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'criterio 4 / RF-010 / D4'; que_verifica := 'Corregir el nombre del cliente NO altera el presupuesto emitido';
  begin
    insert into clientes (nombre) values ('ZZQA Nombre Como Se Imprimio')
      returning id_cliente into v_cli;
    insert into trabajos (numero_presupuesto, origen_carga, id_cliente, txt_cliente)
      values (99990020,'manual', v_cli, 'ZZQA Nombre Como Se Imprimio')
      returning id_trabajo into v_tra;
    update clientes c set nombre = 'ZZQA Nombre Corregido Despues' where c.id_cliente = v_cli;
    select (t.txt_cliente = 'ZZQA Nombre Como Se Imprimio'
            and vp.cliente_actual = 'ZZQA Nombre Corregido Despues')
      into v_bool
      from trabajos t join vw_presupuestos vp on vp.id_trabajo = t.id_trabajo
     where t.id_trabajo = v_tra;
    estado := case when v_bool then 'PASA' else 'FALLA' end;
    obs := case when v_bool then 'el papel dice lo que decía; la ficha, lo de hoy'
                else 'el snapshot se contaminó con el maestro' end;
  exception when others then
    estado := 'FALLA'; obs := sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'criterio 3 / E2'; que_verifica := 'Segundo presupuesto sobre la misma patente: reusa el vehículo';
  begin
    insert into vehiculos (patente, descripcion) values ('ZZQA777','ZZQA Ford Ranger')
      returning id_vehiculo into v_veh;
    insert into trabajos (numero_presupuesto, origen_carga, id_vehiculo, txt_cliente)
      values (99990030,'manual', v_veh, 'ZZQA duenio uno');
    insert into trabajos (numero_presupuesto, origen_carga, id_vehiculo, txt_cliente)
      values (99990031,'manual', v_veh, 'ZZQA duenio dos');
    select count(*) into v_int from vehiculos v where v.patente_norm='ZZQA777';
    select count(*) into v_num from trabajos t where t.id_vehiculo = v_veh;
    estado := case when v_int=1 and v_num=2 then 'PASA' else 'FALLA' end;
    obs := v_int || ' vehículo, ' || v_num || ' presupuestos, dueños distintos (RF-012)';
  exception when others then
    estado := 'FALLA'; obs := sqlerrm;
  end;
  return next;

  -- =====================================================================
  bloque := 'acceso';
  -- =====================================================================

  nro := nro + 1; ref := 'D8 / T007'; que_verifica := 'anon NO lee las tablas';
  begin
    set local role anon;
    select count(*) into v_int from clientes;
    reset role;
    estado := case when v_int=0 then 'PASA' else 'FALLA' end;
    obs := case when v_int=0 then 'sin privilegio o RLS filtra todo'
                else 'anon leyó ' || v_int || ' filas' end;
  exception when insufficient_privilege then
    reset role; estado := 'PASA'; obs := 'permission denied (42501)';
  when others then
    reset role; estado := 'FALLA'; obs := 'error inesperado: ' || sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'D8 / T009'; que_verifica := 'anon NO lee la vista';
  begin
    set local role anon;
    select count(*) into v_int from vw_presupuestos;
    reset role;
    estado := case when v_int=0 then 'PASA' else 'FALLA' end;
    obs := case when v_int=0 then 'sin privilegio o RLS filtra todo'
                else 'anon leyó ' || v_int || ' presupuestos' end;
  exception when insufficient_privilege then
    reset role; estado := 'PASA'; obs := 'permission denied (42501)';
  when others then
    reset role; estado := 'FALLA'; obs := 'error inesperado: ' || sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'D8 / T007'; que_verifica := 'anon NO escribe';
  begin
    set local role anon;
    insert into clientes (nombre) values ('ZZQA anon no deberia poder');
    reset role;
    estado := 'FALLA'; obs := 'anon escribió una fila';
  exception when insufficient_privilege then
    reset role; estado := 'PASA'; obs := 'permission denied (42501)';
  when others then
    reset role; estado := 'PASA'; obs := 'rechazado: ' || left(sqlerrm,60);
  end;
  return next;

  nro := nro + 1; ref := 'D8 / T007'; que_verifica := 'authenticated SÍ lee la vista';
  begin
    set local role authenticated;
    select count(*) into v_int from vw_presupuestos;
    reset role;
    estado := case when v_int > 0 then 'PASA' else 'FALLA' end;
    obs := 'leyó ' || v_int || ' presupuestos';
  exception when others then
    reset role; estado := 'FALLA';
    obs := 'la aplicación NO va a poder leer: ' || sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'D8 / T007'; que_verifica := 'authenticated SÍ escribe';
  begin
    set local role authenticated;
    insert into clientes (nombre) values ('ZZQA escrito por authenticated');
    reset role;
    estado := 'PASA'; obs := 'insert aceptado';
  exception when others then
    reset role; estado := 'FALLA';
    obs := 'la aplicación NO va a poder cargar: ' || sqlerrm;
  end;
  return next;

  -- =====================================================================
  bloque := 'hallazgos abiertos';
  -- =====================================================================

  nro := nro + 1; ref := 'H1'; que_verifica := 'Buscar sin tilde encuentra un nombre con tilde';
  begin
    insert into clientes (nombre) values ('ZZQA Peréz Acentuado');
    select count(*) into v_int from clientes c where c.nombre ilike '%zzqa perez%';
    estado := case when v_int > 0 then 'PASA' else 'ABIERTO' end;
    obs := case when v_int > 0 then 'la busqueda ignora acentos'
                else 'ILIKE no ignora acentos: 0 resultados. Ver qa-hallazgos.md H1' end;
  exception when others then
    estado := 'FALLA'; obs := sqlerrm;
  end;
  return next;

  nro := nro + 1; ref := 'H3'; que_verifica := 'La validación de patente acepta texto crudo (minúsculas)';
  v_bool := fn_es_formato_patente_valido('aar222');
  estado := case when v_bool then 'PASA' else 'ABIERTO' end;
  obs := case when v_bool then 'normaliza internamente'
              else 'devuelve false con la patente cruda. Ver H3 — pendiente de decisión' end;
  return next;

  nro := nro + 1; ref := 'H5'; que_verifica := 'Un número borrado NO se puede reusar (RF-020)';
  begin
    insert into trabajos (numero_presupuesto, origen_carga, txt_cliente)
      values (99990040,'manual','ZZQA reuso');
    delete from trabajos t where t.numero_presupuesto = 99990040;
    insert into trabajos (numero_presupuesto, origen_carga, txt_cliente)
      values (99990040,'manual','ZZQA reuso otra vez');
    estado := 'ABIERTO';
    obs := 'el número volvió a estar libre tras borrarlo. Ver H5 — pendiente de decisión';
  exception when unique_violation then
    estado := 'PASA'; obs := 'el número quedó reservado para siempre';
  when others then
    estado := 'FALLA'; obs := sqlerrm;
  end;
  return next;

  -- ---------------- limpieza final ----------------
  delete from trabajos  where numero_presupuesto between 99990000 and 99999999;
  delete from trabajos  where txt_cliente like 'ZZQA%';
  delete from vehiculos where patente like 'ZZQA%';
  delete from clientes  where nombre  like 'ZZQA%';

  nro := nro + 1; bloque := 'cierre'; ref := 'H9';
  que_verifica := 'La base quedó sin datos de prueba del QA';
  select (select count(*) from clientes  c where c.nombre  like 'ZZQA%')
       + (select count(*) from vehiculos v where v.patente like 'ZZQA%')
       + (select count(*) from trabajos  t where t.numero_presupuesto between 99990000 and 99999999)
    into v_int;
  estado := case when v_int=0 then 'PASA' else 'FALLA' end;
  obs := v_int || ' filas ZZQA remanentes';
  return next;

  return;
end;
$fn$;

-- La función escribe: nadie que no sea el dueño de la base puede invocarla.
revoke all on function fn_qa_001_presupuesto() from public;
revoke all on function fn_qa_001_presupuesto() from anon;
revoke all on function fn_qa_001_presupuesto() from authenticated;

-- Última sentencia: es lo único que el editor va a mostrar, y es la matriz completa.
select * from fn_qa_001_presupuesto();
