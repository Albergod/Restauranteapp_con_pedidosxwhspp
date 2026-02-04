const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const { processMessage } = require('./bot');

console.log('🚀 Iniciando bot de WhatsApp para Restaurante...\n');

const client = new Client({
  authStrategy: new LocalAuth({
    dataPath: './.wwebjs_auth'
  }),
  puppeteer: {
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-accelerated-2d-canvas',
      '--no-first-run',
      '--no-zygote',
      '--disable-gpu'
    ]
  }
});

client.on('qr', (qr) => {
  console.log('\n📱 Escanea este código QR con WhatsApp:\n');
  qrcode.generate(qr, { small: true });
  console.log('\n💡 Abre WhatsApp > Dispositivos vinculados > Vincular dispositivo\n');
});

client.on('ready', () => {
  console.log('✅ ¡Bot de WhatsApp conectado y listo!');
  console.log('📱 Ahora los clientes pueden escribir para hacer pedidos.\n');
});

client.on('authenticated', () => {
  console.log('🔐 Autenticación exitosa');
});

client.on('auth_failure', (msg) => {
  console.error('❌ Error de autenticación:', msg);
});

client.on('disconnected', (reason) => {
  console.log('📴 Bot desconectado:', reason);
  client.initialize();
});

client.on('message', async (message) => {
  const chat = await message.getChat();
  if (chat.isGroup) return;
  if (message.fromMe) return;
  if (message.isStatus) return;

  const phoneNumber = message.from;
  const messageText = message.body;

  const contact = await message.getContact();
  const senderName = contact.pushname || contact.name || 'Cliente';

  console.log(`📩 Mensaje de ${senderName} (${phoneNumber}): ${messageText}`);

  try {
    const response = await processMessage(phoneNumber, messageText, senderName);
    await message.reply(response);
    console.log(`📤 Respuesta enviada a ${senderName}`);
  } catch (error) {
    console.error('Error procesando mensaje:', error);
    await message.reply('❌ Ocurrió un error. Por favor, intenta de nuevo escribiendo *menú*.');
  }
});

process.on('SIGINT', async () => {
  console.log('\n👋 Cerrando bot...');
  await client.destroy();
  process.exit(0);
});

console.log('⏳ Conectando a WhatsApp Web...\n');
client.initialize();
