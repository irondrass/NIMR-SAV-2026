begin;
set local search_path = extensions, public, auth, storage, pg_catalog;
select plan(48);

insert into auth.users (id, aud, role, email, encrypted_password, raw_user_meta_data)
values
 ('11000000-0000-4000-8000-000000000001','authenticated','authenticated','chef@local.test','x','{}'),
 ('11000000-0000-4000-8000-000000000002','authenticated','authenticated','technicien@local.test','x','{}'),
 ('11000000-0000-4000-8000-000000000003','authenticated','authenticated','directeur@local.test','x','{}'),
 ('11000000-0000-4000-8000-000000000004','authenticated','authenticated','admin@local.test','x','{}');

insert into public.organizations (id, code, name) values
 ('11000000-0000-4000-8000-000000000101','ORG_TASK_A','Organisation tâches A'),
 ('11000000-0000-4000-8000-000000000102','ORG_TASK_B','Organisation tâches B');
insert into public.sites (id, organization_id, code, name, city) values
 ('11000000-0000-4000-8000-000000000201','11000000-0000-4000-8000-000000000101','SITE_TASK_A','Site tâches A','Tunis'),
 ('11000000-0000-4000-8000-000000000202','11000000-0000-4000-8000-000000000102','SITE_TASK_B','Site tâches B','Sfax');

insert into public.profile_roles (profile_id, role_id, assigned_by)
select '11000000-0000-4000-8000-000000000001', id, '11000000-0000-4000-8000-000000000004' from public.roles where code = 'CHEF_ATELIER';
insert into public.profile_roles (profile_id, role_id, assigned_by)
select '11000000-0000-4000-8000-000000000003', id, '11000000-0000-4000-8000-000000000004' from public.roles where code = 'DIRECTEUR_SAV';
insert into public.profile_roles (profile_id, role_id, assigned_by)
select '11000000-0000-4000-8000-000000000002', id, '11000000-0000-4000-8000-000000000004' from public.roles where code = 'TECHNICIEN';
insert into public.profile_roles (profile_id, role_id, assigned_by)
select '11000000-0000-4000-8000-000000000004', id, '11000000-0000-4000-8000-000000000004' from public.roles where code = 'ADMIN_TECHNIQUE';
insert into public.profile_site_access (profile_id, site_id, access_scope, assigned_by) values
 ('11000000-0000-4000-8000-000000000001','11000000-0000-4000-8000-000000000201','OPERATE','11000000-0000-4000-8000-000000000004'),
 ('11000000-0000-4000-8000-000000000002','11000000-0000-4000-8000-000000000201','OPERATE','11000000-0000-4000-8000-000000000004'),
 ('11000000-0000-4000-8000-000000000003','11000000-0000-4000-8000-000000000201','MANAGE','11000000-0000-4000-8000-000000000004'),
 ('11000000-0000-4000-8000-000000000004','11000000-0000-4000-8000-000000000201','MANAGE','11000000-0000-4000-8000-000000000004');

insert into public.quote_import_operations (id, organization_id, site_id, operation_key, status, source_file_name, source_file_size, source_mime_type, source_file_hash, detected_format, created_by, approved_by, approved_at)
values
 ('11000000-0000-4000-8000-000000000301','11000000-0000-4000-8000-000000000101','11000000-0000-4000-8000-000000000201','task-source-a','APPROVED','devis-a.csv',1,'text/csv',repeat('a',64),'CSV','11000000-0000-4000-8000-000000000001','11000000-0000-4000-8000-000000000003',now()),
 ('11000000-0000-4000-8000-000000000302','11000000-0000-4000-8000-000000000102','11000000-0000-4000-8000-000000000202','task-source-b','APPROVED','devis-b.csv',1,'text/csv',repeat('b',64),'CSV','11000000-0000-4000-8000-000000000003','11000000-0000-4000-8000-000000000003',now());
insert into public.quote_import_rows (id, import_operation_id, source_row_number, source_values, validation_status)
values
 ('11000000-0000-4000-8000-000000000401','11000000-0000-4000-8000-000000000301',1,'{"description":"Réparation pare-chocs","category":"BODYWORK"}','VALID'),
 ('11000000-0000-4000-8000-000000000402','11000000-0000-4000-8000-000000000302',1,'{"description":"Diagnostic","category":"DIAGNOSTIC"}','VALID');
insert into public.dossiers (id, organization_id, site_id, quote_import_operation_id, quote_import_row_id, dossier_number, source_snapshot, repair_order_snapshot, created_by, updated_by)
values
 ('11000000-0000-4000-8000-000000000501','11000000-0000-4000-8000-000000000101','11000000-0000-4000-8000-000000000201','11000000-0000-4000-8000-000000000301','11000000-0000-4000-8000-000000000401','DOS-TASK-A','{}','{}','11000000-0000-4000-8000-000000000001','11000000-0000-4000-8000-000000000001'),
 ('11000000-0000-4000-8000-000000000502','11000000-0000-4000-8000-000000000102','11000000-0000-4000-8000-000000000202','11000000-0000-4000-8000-000000000302','11000000-0000-4000-8000-000000000402','DOS-TASK-B','{}','{}','11000000-0000-4000-8000-000000000003','11000000-0000-4000-8000-000000000003');
insert into public.repair_orders (id, dossier_id, organization_id, site_id, source_import_operation_id, source_import_row_id, provenance_snapshot)
values
 ('11000000-0000-4000-8000-000000000601','11000000-0000-4000-8000-000000000501','11000000-0000-4000-8000-000000000101','11000000-0000-4000-8000-000000000201','11000000-0000-4000-8000-000000000301','11000000-0000-4000-8000-000000000401','{}'),
 ('11000000-0000-4000-8000-000000000602','11000000-0000-4000-8000-000000000502','11000000-0000-4000-8000-000000000102','11000000-0000-4000-8000-000000000202','11000000-0000-4000-8000-000000000302','11000000-0000-4000-8000-000000000402','{}');
insert into public.repair_order_lines (id, repair_order_id, source_import_row_id, line_order, source_row_number, description, operation_category, quantity, unit, planned_duration_minutes, source_reference, provenance)
values
 ('11000000-0000-4000-8000-000000000701','11000000-0000-4000-8000-000000000601','11000000-0000-4000-8000-000000000401',1,1,'Réparation pare-chocs','BODYWORK',1,'job',360,'RO-A-1','{}'),
 ('11000000-0000-4000-8000-000000000702','11000000-0000-4000-8000-000000000602','11000000-0000-4000-8000-000000000402',1,1,'Diagnostic électrique','ELECTRICAL',1,'job',60,'RO-B-1','{}');

set local role authenticated;
select set_config('request.jwt.claim.sub','11000000-0000-4000-8000-000000000001',true);

select lives_ok($$select public.create_workshop_task_from_repair_order_line('11000000-0000-4000-8000-000000000701','depose',1,60,'NORMAL',null,null,null)$$, 'création contrôlée depuis une ligne');
select lives_ok($$select public.create_workshop_task_from_repair_order_line('11000000-0000-4000-8000-000000000701','reparation',2,120,'HIGH','Réparation','BODYWORK',null)$$, 'plusieurs tâches pour une ligne');
select is((select count(*) from public.workshop_tasks where source_repair_order_line_id='11000000-0000-4000-8000-000000000701'),2::bigint,'la relation ligne vers tâches est un-à-plusieurs');
select throws_ok($$select public.create_workshop_task_from_repair_order_line('11000000-0000-4000-8000-000000000701','DEPOSE',3,60)$$,null,null,'clé de tâche dupliquée rejetée');
select throws_ok($$select public.create_workshop_task_from_repair_order_line('11000000-0000-4000-8000-000000000701','autre',1,60)$$,null,null,'séquence de tâche dupliquée rejetée');
select throws_ok($$select public.create_workshop_task_from_repair_order_line('11000000-0000-4000-8000-000000000701','zero',3,0)$$,null,null,'durée nulle rejetée');
select throws_ok($$select public.create_workshop_task_from_repair_order_line('11000000-0000-4000-8000-000000000701','negative',3,-1)$$,null,null,'durée négative rejetée');
select throws_ok($$select public.create_workshop_task_from_repair_order_line('11000000-0000-4000-8000-000000009999','invalide',1,10)$$,null,null,'ligne source invalide rejetée');
select is((select count(*) from public.workshop_tasks where source_repair_order_line_id='11000000-0000-4000-8000-000000000701'),2::bigint,'échec de création atomique sans ligne partielle');
select is((select task_key from public.workshop_tasks where task_key='DEPOSE'),'DEPOSE','clé normalisée');
reset role;
select is((select coalesce(task_label,rol.description) from public.workshop_tasks wt join public.repair_order_lines rol on rol.id=wt.source_repair_order_line_id where wt.task_key='DEPOSE'),'Réparation pare-chocs','libellé effectif hérité');
select is((select coalesce(task_category,rol.operation_category) from public.workshop_tasks wt join public.repair_order_lines rol on rol.id=wt.source_repair_order_line_id where wt.task_key='DEPOSE'),'BODYWORK','catégorie effective héritée');
select is((select task_label from public.workshop_tasks where task_key='REPARATION'),'Réparation','libellé de décomposition');
set local role authenticated;
select set_config('request.jwt.claim.sub','11000000-0000-4000-8000-000000000001',true);
select throws_ok($$insert into public.workshop_tasks (organization_id,site_id,repair_order_id,source_repair_order_line_id,task_key,task_sequence,planned_duration_minutes,created_by,updated_by) values ('11000000-0000-4000-8000-000000000101','11000000-0000-4000-8000-000000000201','11000000-0000-4000-8000-000000000601','11000000-0000-4000-8000-000000000701','DIRECT',20,10,auth.uid(),auth.uid())$$,'42501',null,'insertion directe refusée');
select throws_ok($$update public.workshop_tasks set source_repair_order_line_id='11000000-0000-4000-8000-000000000702' where task_key='DEPOSE'$$,'42501',null,'provenance source immuable');
reset role;
select isnt_empty($$select id from public.audit_events where event_type='WORKSHOP_TASK.CREATED'$$,'création auditée');
set local role authenticated;
select set_config('request.jwt.claim.sub','11000000-0000-4000-8000-000000000001',true);

select lives_ok($$select public.create_workshop_task_skill_requirement((select id from public.workshop_tasks where task_key='DEPOSE'),'mecanique',true)$$,'compétence créée et normalisée');
select throws_ok($$select public.create_workshop_task_skill_requirement((select id from public.workshop_tasks where task_key='DEPOSE'),'MECANIQUE',true)$$,null,null,'compétence dupliquée rejetée');
select throws_ok($$select public.create_workshop_task_skill_requirement((select id from public.workshop_tasks where task_key='DEPOSE'),'   ',true)$$,null,null,'code compétence vide rejeté');
select lives_ok($$select public.create_workshop_task_resource_requirement((select id from public.workshop_tasks where task_key='DEPOSE'),'zone diagnostic',2,true)$$,'capacité opérationnelle créée');
select is((select resource_capability_code from public.task_resource_requirements where task_id=(select id from public.workshop_tasks where task_key='DEPOSE')),'ZONE_DIAGNOSTIC','capacité normalisée');
select throws_ok($$select public.create_workshop_task_resource_requirement((select id from public.workshop_tasks where task_key='DEPOSE'),'PONT',0,true)$$,null,null,'quantité nulle rejetée');
select throws_ok($$select public.create_workshop_task_resource_requirement((select id from public.workshop_tasks where task_key='DEPOSE'),'PONT',-1,true)$$,null,null,'quantité négative rejetée');
select throws_ok($$insert into public.task_skill_requirements (organization_id,site_id,task_id,skill_code,created_by) values ('11000000-0000-4000-8000-000000000101','11000000-0000-4000-8000-000000000201',(select id from public.workshop_tasks where task_key='DEPOSE'),'DIRECT',auth.uid())$$,'42501',null,'insertion directe compétence refusée');

select lives_ok($$select public.create_workshop_task_dependency((select id from public.workshop_tasks where task_key='DEPOSE'),(select id from public.workshop_tasks where task_key='REPARATION'))$$,'dépendance créée');
select throws_ok($$select public.create_workshop_task_dependency((select id from public.workshop_tasks where task_key='DEPOSE'),(select id from public.workshop_tasks where task_key='DEPOSE'))$$,null,null,'auto-dépendance rejetée');
select throws_ok($$select public.create_workshop_task_dependency((select id from public.workshop_tasks where task_key='DEPOSE'),(select id from public.workshop_tasks where task_key='REPARATION'))$$,null,null,'dépendance dupliquée rejetée');
select throws_ok($$select public.create_workshop_task_dependency((select id from public.workshop_tasks where task_key='REPARATION'),(select id from public.workshop_tasks where task_key='DEPOSE'))$$,null,null,'cycle rejeté');
select throws_ok($$select public.create_workshop_task_dependency('11000000-0000-4000-8000-000000009999',(select id from public.workshop_tasks where task_key='REPARATION'))$$,null,null,'prédécesseur invalide rejeté');

select lives_ok($$select public.transition_workshop_task((select id from public.workshop_tasks where task_key='DEPOSE'),1,'PLANNED')$$,'transition READY vers PLANNED');
select lives_ok($$select public.transition_workshop_task((select id from public.workshop_tasks where task_key='DEPOSE'),2,'IN_PROGRESS')$$,'transition PLANNED vers IN_PROGRESS');
select throws_ok($$select public.transition_workshop_task((select id from public.workshop_tasks where task_key='DEPOSE'),3,'READY')$$,null,null,'transition invalide rejetée');
select lives_ok($$select public.transition_workshop_task((select id from public.workshop_tasks where task_key='DEPOSE'),3,'COMPLETED')$$,'transition vers COMPLETED');
select throws_ok($$select public.transition_workshop_task((select id from public.workshop_tasks where task_key='DEPOSE'),4,'READY')$$,null,null,'tâche terminée non réouverte');

select lives_ok($$select public.create_workshop_task_from_repair_order_line('11000000-0000-4000-8000-000000000701','hold',3,30)$$,'création de la tâche mise en attente') ;
select throws_ok($$select public.transition_workshop_task((select id from public.workshop_tasks where task_key='HOLD'),1,'ON_HOLD')$$,null,null,'mise en attente sans motif rejetée');
select lives_ok($$select public.transition_workshop_task((select id from public.workshop_tasks where task_key='HOLD'),1,'ON_HOLD','Attente décision atelier')$$,'mise en attente avec motif acceptée');
select is((select hold_reason from public.workshop_tasks where task_key='HOLD'),'Attente décision atelier','motif de mise en attente persisté');
select lives_ok($$select public.transition_workshop_task((select id from public.workshop_tasks where task_key='HOLD'),2,'READY')$$,'sortie de mise en attente auditée');
select is((select hold_reason from public.workshop_tasks where task_key='HOLD'),null,'motif courant nettoyé à la reprise');
select throws_ok($$select public.create_workshop_task_dependency((select id from public.workshop_tasks where task_key='DEPOSE'),'11000000-0000-4000-8000-000000000702')$$,null,null,'dépendance inter-organisation refusée');
select set_config('request.jwt.claim.sub','11000000-0000-4000-8000-000000000002',true);
select throws_ok($$select public.create_workshop_task_from_repair_order_line('11000000-0000-4000-8000-000000000701','TECH',10,30)$$,'42501',null,'technicien sans droit de mutation');
select is_empty($$select id from public.workshop_tasks where site_id='11000000-0000-4000-8000-000000000202'$$,'accès inter-site refusé');
select is_empty($$select id from public.workshop_tasks where organization_id='11000000-0000-4000-8000-000000000102'$$,'accès inter-organisation refusé');
select throws_ok($$insert into public.task_resource_requirements (organization_id,site_id,task_id,resource_capability_code,quantity_required,created_by) values ('11000000-0000-4000-8000-000000000101','11000000-0000-4000-8000-000000000201',(select id from public.workshop_tasks where task_key='DEPOSE'),'DIRECT',1,auth.uid())$$,'42501',null,'insertion directe capacité refusée');
reset role;
select is((select count(*) from public.audit_events where event_type in ('WORKSHOP_TASK.CREATED','WORKSHOP_TASK.STATUS_CHANGED','WORKSHOP_TASK.ON_HOLD','WORKSHOP_TASK.DEPENDENCY_CREATED','WORKSHOP_TASK.SKILL_REQUIRED','WORKSHOP_TASK.RESOURCE_REQUIRED')),11::bigint,'événements opérationnels audités');
select is((select actor_profile_id from public.audit_events where event_type='WORKSHOP_TASK.CREATED' order by created_at desc limit 1),'11000000-0000-4000-8000-000000000001'::uuid,'acteur dérivé de auth.uid');
select is((select count(*) from information_schema.columns where table_schema='public' and table_name in ('workshop_tasks','task_dependencies','task_skill_requirements','task_resource_requirements') and column_name in ('amount','price','currency','invoice','billing','payment')),0::bigint,'aucun champ commercial dans le modèle');

select * from finish();
rollback;
