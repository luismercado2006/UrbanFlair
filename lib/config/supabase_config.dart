/// Credenciales públicas de Supabase.
///
/// La URL es la del proyecto (SIN /rest/v1: el SDK la agrega solo).
/// La anon key está en: Supabase > Project Settings > API > "anon public".
/// Es seguro que la anon key vaya en la app, porque la protección real son
/// las políticas RLS del archivo supabase_schema.sql.
/// NUNCA pongas aquí la "service_role" key.
///
/// Opcional (para no dejarla en el código):
///   flutter run --dart-define=SUPABASE_ANON_KEY=tu_clave
class SupabaseConfig {
  static const url = 'https://pqdghhsenngbwinmruku.supabase.co';
  static const anonKey = String.fromEnvironment(
    'https://pqdghhsenngbwinmruku.supabase.co/rest/v1/',
    defaultValue: 'sb_publishable_u8YXHTwKBmG_s54W8M_41Q_LKv1yLMt',
  );
}
