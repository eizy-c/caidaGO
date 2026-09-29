/// Páginas web HTML estáticas para el servidor online de CaidaGO.
/// Cumplen los requisitos legales de Meta / Facebook Developers y Google Play.

class WebPages {
  static String get privacyPolicyHtml => '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Política de Privacidad - CaidaGO</title>
  <style>
    :root {
      --bg: #130f35;
      --card-bg: #1c164a;
      --text: #e2e8f0;
      --text-muted: #94a3b8;
      --accent: #38bdf8;
      --yellow: #facc15;
      --border: #312a6d;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      line-height: 1.6;
      margin: 0;
      padding: 24px 16px;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background: var(--card-bg);
      border: 2px solid var(--border);
      border-radius: 18px;
      padding: 36px 28px;
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
    }
    h1 {
      color: var(--yellow);
      margin-top: 0;
      font-size: 26px;
      border-bottom: 2px solid var(--border);
      padding-bottom: 12px;
    }
    h2 {
      color: var(--accent);
      font-size: 18px;
      margin-top: 24px;
    }
    p, li {
      color: var(--text);
      font-size: 14.5px;
    }
    ul {
      padding-left: 20px;
    }
    .badge {
      display: inline-block;
      background: #0f172a;
      color: var(--accent);
      padding: 4px 10px;
      border-radius: 8px;
      font-size: 12px;
      font-weight: bold;
      border: 1px solid var(--border);
    }
    .footer {
      margin-top: 32px;
      padding-top: 16px;
      border-top: 1px solid var(--border);
      color: var(--text-muted);
      font-size: 12.5px;
      text-align: center;
    }
    a {
      color: var(--accent);
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
  </style>
</head>
<body>
  <div class="container">
    <span class="badge">CaidaGO &bull; Juego de Cartas</span>
    <h1>Política de Privacidad</h1>
    <p><strong>Última actualización:</strong> 29 de septiembre de 2026</p>

    <p>Esta Política de Privacidad describe cómo <strong>CaidaGO</strong> recopila, utiliza y protege la información del usuario cuando utiliza nuestra aplicación móvil y nuestros servicios en línea.</p>

    <h2>1. Información que recopilamos</h2>
    <p>Cuando utilizas la funcionalidad de inicio de sesión con Facebook (Facebook Login) o juegas en salas multijugador en línea, podemos recopilar la siguiente información estrictamente necesaria:</p>
    <ul>
      <li><strong>Datos del perfil público de Facebook:</strong> Tu nombre público de usuario, tu foto de perfil pública y tu identificador único de usuario de Facebook (Facebook User ID).</li>
      <li><strong>Datos de juego generados:</strong> Nivel de jugador, puntos de experiencia (XP), saldo virtual de monedas y gemas del juego, estadísticas de partidas (victorias, derrotas, caídas cantadas) y logros desbloqueados.</li>
    </ul>
    <p><strong>No recopilamos:</strong> Contraseñas, números de teléfono, contactos privados, datos de ubicación GPS en tiempo real ni información financiera o de tarjetas de crédito.</p>

    <h2>2. Uso de la información</h2>
    <p>La información recopilada se utiliza exclusivamente para los siguientes fines:</p>
    <ul>
      <li>Autenticar y validar tu cuenta de jugador en el juego.</li>
      <li>Mostrar tu nombre y foto de perfil en la mesa de juego para que tus rivales y compañeros puedan identificarte.</li>
      <li>Guardar de manera persistente tu progreso, nivel, rango y monedas para que no se pierdan al cambiar de dispositivo.</li>
      <li>Permitir la participación en clasificaciones y tablas de líderes.</li>
    </ul>

    <h2>3. Compartición y divulgación de datos</h2>
    <p><strong>CaidaGO no vende, no alquila y no comercializa datos de usuario con terceros con fines publicitarios.</strong> La información de tu perfil sólo es visible dentro de la partida para los demás jugadores con quienes estés disputando una mesa de juego.</p>

    <h2>4. Seguridad de los datos</h2>
    <p>Implementamos medidas técnicas y de seguridad estándar en la industria para proteger tus datos. Todas las conexiones de red entre el juego y el servidor se realizan mediante protocolos seguros y cifrados (HTTPS y WSS).</p>

    <h2>5. Eliminación de datos del usuario</h2>
    <p>Respetamos tu derecho a solicitar la eliminación de tu información. Puedes consultar las instrucciones detalladas de eliminación en cualquier momento visitando nuestra página de <a href="/data-deletion">Instrucciones de Eliminación de Datos</a> o contactándonos directamente a nuestro correo de soporte.</p>

    <h2>6. Contacto</h2>
    <p>Si tienes alguna pregunta o inquietud acerca de esta Política de Privacidad o del tratamiento de tus datos, puedes ponerte en contacto con nosotros a través de:</p>
    <p><strong>Correo electrónico:</strong> <a href="mailto:eizycast5@gmail.com">eizycast5@gmail.com</a></p>

    <div class="footer">
      &copy; 2026 CaidaGO. Todos los derechos reservados.
    </div>
  </div>
</body>
</html>
''';

  static String get dataDeletionInstructionsHtml => '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Eliminación de Datos de Usuario - CaidaGO</title>
  <style>
    :root {
      --bg: #130f35;
      --card-bg: #1c164a;
      --text: #e2e8f0;
      --text-muted: #94a3b8;
      --accent: #38bdf8;
      --yellow: #facc15;
      --border: #312a6d;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      line-height: 1.6;
      margin: 0;
      padding: 24px 16px;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background: var(--card-bg);
      border: 2px solid var(--border);
      border-radius: 18px;
      padding: 36px 28px;
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
    }
    h1 {
      color: var(--yellow);
      margin-top: 0;
      font-size: 24px;
      border-bottom: 2px solid var(--border);
      padding-bottom: 12px;
    }
    h2 {
      color: var(--accent);
      font-size: 17px;
      margin-top: 24px;
    }
    p, li {
      color: var(--text);
      font-size: 14.5px;
    }
    ol {
      padding-left: 20px;
    }
    li {
      margin-bottom: 10px;
    }
    .step-box {
      background: #0f172a;
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 16px;
      margin: 16px 0;
    }
    .footer {
      margin-top: 32px;
      padding-top: 16px;
      border-top: 1px solid var(--border);
      color: var(--text-muted);
      font-size: 12.5px;
      text-align: center;
    }
    a {
      color: var(--accent);
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Instrucciones para la Eliminación de Datos de Usuario</h1>
    <p>En cumplimiento con las Políticas de Datos de Plataforma de Meta (Facebook Developers) y las normativas internacionales de privacidad, en <strong>CaidaGO</strong> respetamos tu derecho a solicitar la eliminación de cualquier dato personal asociado a tu cuenta.</p>

    <h2>Opción 1: Desvincular CaidaGO desde tu cuenta de Facebook</h2>
    <div class="step-box">
      <ol>
        <li>Inicia sesión en tu cuenta de Facebook en la aplicación o el navegador.</li>
        <li>Dirígete a <strong>Configuración y privacidad</strong> y luego selecciona <strong>Configuración</strong>.</li>
        <li>En el menú de la izquierda o en la sección de Permisos, selecciona <strong>Apps y sitios web</strong>.</li>
        <li>Busca <strong>CaidaGO</strong> en la lista de aplicaciones activas.</li>
        <li>Haz clic en el botón <strong>Eliminar</strong> junto a la aplicación.</li>
        <li>Confirma la eliminación. Al hacer esto, Facebook revocará el acceso de CaidaGO a tu información y notificará a nuestros servidores.</li>
      </ol>
    </div>

    <h2>Opción 2: Solicitud de eliminación manual completa</h2>
    <p>Si deseas que eliminemos definitivamente de nuestros servidores todo tu historial de juego, saldo virtual de monedas, trofeos y registros asociados a tu identificador de Facebook, puedes solicitarlo por correo electrónico:</p>
    <div class="step-box">
      <p>Envía un correo a: <a href="mailto:eizycast5@gmail.com"><strong>eizycast5@gmail.com</strong></a> con la siguiente información:</p>
      <ul>
        <li><strong>Asunto:</strong> Solicitud de eliminación de datos de CaidaGO</li>
        <li><strong>Cuerpo del mensaje:</strong> Tu nombre de usuario en el juego o el enlace de tu perfil de Facebook para localizar tu registro.</li>
      </ul>
      <p>Procesaremos tu solicitud y eliminaremos de forma irrevocable tus datos de nuestros sistemas en un plazo máximo de <strong>48 horas hábiles</strong>, enviándote un correo de confirmación una vez completado el proceso.</p>
    </div>

    <p style="margin-top: 24px;">Para más información, puedes consultar nuestra <a href="/privacy">Política de Privacidad</a>.</p>

    <div class="footer">
      &copy; 2026 CaidaGO. Soporte técnico: eizycast5@gmail.com
    </div>
  </div>
</body>
</html>
''';
}
