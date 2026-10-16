# Torneo Interescuelas de Kickball UTB · 2026-2

Sitio del torneo: calendario, marcadores por entrada, tabla de posiciones, evidencias, equipos con nóminas descargables en Excel y reglamento.

Equipos: **EIAD**, **ENLS** y **ETD**. Partidos a las 5:00 p. m. en la cancha de softbol. Organiza: Centro Deportivo y Cultural · Universidad Tecnológica de Bolívar.

Página publicada: https://cdcutb.github.io/kickball-utb/

## Archivos

- `index.html`: toda la página.
- `config.js`: datos de conexión a Supabase (resultados, evidencias y usuarios con clave).
- `resultados.json`: resultados para el modo consulta (si `config.js` está vacío).
- `supabase-setup.sql`: script que crea tablas, permisos y el espacio para fotos.

## Conectar Supabase (una sola vez)

1. Crea un proyecto gratuito en supabase.com.
2. En **SQL Editor → New query**, pega `supabase-setup.sql` y pulsa **Run**.
3. En **Authentication**, desactiva **Allow new users to sign up**.
4. En **Authentication → Users → Add user**, crea cada usuario con correo y clave (marca *Auto Confirm User*).
   Para que alguien cargue resultados, agrega su correo: `insert into public.organizadores (email) values ('correo@utb.edu.co');`
5. En **Project Settings → API**, copia **Project URL** y **anon public key** en `config.js`.
