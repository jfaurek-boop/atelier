# Supabase para Atelier

Atelier usa Supabase para sincronizar espacios de trabajo compartidos. Cada espacio guarda el estado completo de la app y puede tener miembros invitados por correo.

## Configuracion inicial

1. Abre tu proyecto en Supabase.
2. Ve a `SQL Editor`.
3. Ejecuta completo `supabase-schema.sql`.
4. En Supabase, ve a `Authentication` y deja habilitado el proveedor `Email`.

La app ya trae configurados:

```text
URL: https://bwlmdduvarsdkunbjkxq.supabase.co
Publishable key: sb_publishable_w3TvyMsq-jw-NSShqkQCZg_PHgXUpss
```

Por eso, en Atelier normalmente solo debes entrar a `Configuracion`, activar Supabase y escribir email + contrasena.

## Crear tu primer espacio

1. Abre Atelier.
2. Entra a `Configuracion`.
3. Marca `Activar sincronizacion con Supabase`.
4. Escribe tu email y contrasena.
5. Si todavia no existe tu usuario, pulsa `Crear cuenta`.
6. Pulsa `Subir datos actuales`.

Si no existe ningun espacio, Atelier crea uno automaticamente.

## Invitar a otra persona

1. En `Configuracion`, entra con tu email y contrasena.
2. En `Espacio de trabajo`, selecciona el espacio.
3. Escribe el correo de la persona en `Invitar por correo`.
4. Elige `Puede editar` o `Solo lectura`.
5. Pulsa `Invitar`.

La persona invitada debe abrir Atelier, activar Supabase y entrar con el mismo correo invitado. Si no tiene usuario, puede pulsar `Crear cuenta`.

## Cambiar entre espacios

En `Configuracion`, usa el selector `Trabajar en` y luego `Cambiar / cargar`.

## Nota tecnica

La base usa estas tablas:

- `atelier_workspaces`: nombre, propietario y estado JSONB.
- `atelier_workspace_members`: miembros por correo, con rol `owner`, `editor` o `viewer`.

Las politicas RLS permiten leer solo espacios donde el usuario es miembro. Solo `owner` y `editor` pueden actualizar el estado; solo `owner` puede invitar miembros.
