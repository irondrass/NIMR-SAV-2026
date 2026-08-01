export const ROLES = ['ADMIN_TECHNIQUE','DIRECTEUR_SAV','CHEF_ATELIER','IMPORT_DEVIS','TECHNICIEN','CONTROLE_QUALITE','RESPONSABLE_GARANTIE','LECTURE_SEULE'] as const;
export type Role = typeof ROLES[number];
export type Permission = 'dashboard.read'|'quote-import.manage'|'imports.read'|'cases.read'|'cases.manage'|'workshop.plan'|'workshop.execute'|'resources.manage'|'technicians.manage'|'teams.manage'|'quality.manage'|'delivery.manage'|'warranty.manage'|'complaints.manage'|'satisfaction.read'|'reports.read'|'users.manage'|'settings.manage'|'audit.read';
export type Site = { id: string; organizationId: string; name: string; city: string; active: boolean };
export type User = { id: string; email: string; displayName: string; roles: Role[]; siteId?: string };

export const ROLE_PERMISSIONS: Record<Role, Permission[]> = {
  ADMIN_TECHNIQUE: ['dashboard.read','imports.read','cases.read','workshop.plan','workshop.execute','resources.manage','technicians.manage','teams.manage','quality.manage','delivery.manage','warranty.manage','complaints.manage','satisfaction.read','reports.read','users.manage','settings.manage','audit.read'],
  DIRECTEUR_SAV: ['dashboard.read','quote-import.manage','imports.read','cases.read','cases.manage','workshop.plan','workshop.execute','resources.manage','technicians.manage','teams.manage','quality.manage','delivery.manage','warranty.manage','complaints.manage','satisfaction.read','reports.read','settings.manage','audit.read'],
  CHEF_ATELIER: ['dashboard.read','imports.read','cases.read','cases.manage','workshop.plan','workshop.execute','resources.manage','technicians.manage','teams.manage','quality.manage','delivery.manage','reports.read'],
  IMPORT_DEVIS: ['dashboard.read','quote-import.manage','imports.read'],
  TECHNICIEN: ['dashboard.read','cases.read','workshop.execute'],
  CONTROLE_QUALITE: ['dashboard.read','cases.read','quality.manage','delivery.manage'],
  RESPONSABLE_GARANTIE: ['dashboard.read','cases.read','warranty.manage','reports.read'],
  LECTURE_SEULE: ['dashboard.read','cases.read','satisfaction.read','reports.read']
};

export function hasPermission(roles: Role[], permission: Permission) { return roles.some((role) => ROLE_PERMISSIONS[role].includes(permission)); }
