const { getMenuItems, createOrder } = require('./database');

const conversations = new Map();

const MENU_KEYWORDS = ['menu', 'menú', 'carta', 'que hay', 'qué hay', 'que tienen', 'qué tienen', 'platos', 'opciones'];

function getConversation(phoneNumber) {
  if (!conversations.has(phoneNumber)) {
    conversations.set(phoneNumber, {
      state: 'idle',
      selectedItems: [],
      customerName: null,
      notes: null,
      menuItems: []
    });
  }
  return conversations.get(phoneNumber);
}

function formatPrice(price) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    minimumFractionDigits: 0
  }).format(price);
}

async function generateMenuMessage() {
  const items = await getMenuItems();
  
  if (items.length === 0) {
    return { message: '😔 Lo sentimos, no hay items disponibles en el menú en este momento.', items: [] };
  }

  let message = '🍽️ *MENÚ DEL DÍA* 🍽️\n\n';
  
  items.forEach((item, index) => {
    message += `*${index + 1}.* ${item.name} - ${formatPrice(item.price)}\n`;
  });
  
  message += '\n📝 *Para hacer un pedido:*\n';
  message += 'Escribe los números de los platos que deseas.\n';
  message += 'Ejemplo: *1, 3* o *2*\n\n';
  message += '💬 También puedes agregar notas como:\n';
  message += '"1, 2 sin sopa y ensalada aparte"';
  
  return { message, items };
}

function parseItemSelection(message, menuItems) {
  const numbers = message.match(/\d+/g);
  if (!numbers) return { items: [], notes: null };

  const selectedItems = [];
  const itemCounts = {};

  for (const numStr of numbers) {
    const index = parseInt(numStr) - 1;
    if (index >= 0 && index < menuItems.length) {
      const menuItem = menuItems[index];
      if (itemCounts[menuItem.id]) {
        itemCounts[menuItem.id].quantity++;
      } else {
        itemCounts[menuItem.id] = {
          menuItemId: menuItem.id,
          name: menuItem.name,
          price: menuItem.price,
          quantity: 1
        };
      }
    }
  }

  for (const id in itemCounts) {
    selectedItems.push(itemCounts[id]);
  }

  let notes = null;
  const notesMatch = message.match(/\d+[,\s\d]*(.+)/);
  if (notesMatch && notesMatch[1]) {
    const possibleNotes = notesMatch[1].trim();
    if (possibleNotes.length > 2 && /[a-záéíóúñ]/i.test(possibleNotes)) {
      notes = possibleNotes;
    }
  }

  return { items: selectedItems, notes };
}

async function processMessage(phoneNumber, messageText, senderName) {
  const message = messageText.toLowerCase().trim();
  const conversation = getConversation(phoneNumber);

  if (message === 'cancelar' || message === 'salir') {
    conversations.delete(phoneNumber);
    return '❌ Pedido cancelado. Escribe *menú* para ver nuestros platos.';
  }

  if (conversation.state === 'waiting_address') {
    const address = messageText.trim();
    
    if (address.length < 5) {
      return '📍 Por favor, escribe una dirección más completa para la entrega.';
    }

    try {
      const { orderId, totalPrice } = await createOrder(
        conversation.customerName || senderName || 'Cliente WhatsApp',
        conversation.selectedItems,
        address,
        conversation.notes
      );

      const selectedItems = conversation.selectedItems;
      const notes = conversation.notes;
      conversations.delete(phoneNumber);

      let confirmMessage = '✅ *¡PEDIDO CONFIRMADO!* ✅\n\n';
      confirmMessage += `📋 *Pedido #${orderId.slice(-6)}*\n\n`;
      
      for (const item of selectedItems) {
        confirmMessage += `• ${item.name} x${item.quantity} - ${formatPrice(item.price * item.quantity)}\n`;
      }
      
      confirmMessage += `\n💰 *Total: ${formatPrice(totalPrice)}*\n`;
      confirmMessage += `📍 *Dirección:* ${address}\n`;
      
      if (notes) {
        confirmMessage += `📝 *Notas:* ${notes}\n`;
      }
      
      confirmMessage += '\n⏰ Tu pedido está siendo preparado.\n';
      confirmMessage += '¡Gracias por tu preferencia! 🙏';

      return confirmMessage;

    } catch (error) {
      console.error('Error creando pedido:', error);
      conversations.delete(phoneNumber);
      return '❌ Hubo un error al procesar tu pedido. Por favor, intenta de nuevo.';
    }
  }

  if (MENU_KEYWORDS.some(keyword => message.includes(keyword))) {
    const { message: menuMessage, items } = await generateMenuMessage();
    conversation.state = 'viewing_menu';
    conversation.menuItems = items;
    return menuMessage;
  }

  if (/\d/.test(message)) {
    let menuItems = conversation.menuItems;
    if (menuItems.length === 0) {
      menuItems = await getMenuItems();
      conversation.menuItems = menuItems;
    }

    const { items, notes } = parseItemSelection(message, menuItems);
    
    if (items.length === 0) {
      return '🤔 No encontré platos válidos en tu selección.\n\nEscribe *menú* para ver las opciones disponibles.';
    }

    conversation.selectedItems = items;
    conversation.notes = notes;
    conversation.customerName = senderName;
    conversation.state = 'waiting_address';

    let confirmItems = '🛒 *Tu pedido:*\n\n';
    let total = 0;
    
    for (const item of items) {
      const subtotal = item.price * item.quantity;
      total += subtotal;
      confirmItems += `• ${item.name} x${item.quantity} - ${formatPrice(subtotal)}\n`;
    }
    
    confirmItems += `\n💰 *Subtotal: ${formatPrice(total)}*\n`;
    
    if (notes) {
      confirmItems += `📝 *Notas:* ${notes}\n`;
    }
    
    confirmItems += '\n📍 Ahora escribe la *dirección de entrega*:\n';
    confirmItems += '(Escribe "cancelar" para cancelar el pedido)';

    return confirmItems;
  }

  let welcomeMessage = '👋 ¡Hola! Bienvenido a nuestro restaurante.\n\n';
  welcomeMessage += '📜 Escribe *menú* para ver nuestros platos del día.\n';
  welcomeMessage += '🛒 O escribe directamente el número del plato que deseas.\n\n';
  welcomeMessage += 'Ejemplo: *1, 3* para pedir los platos 1 y 3.';

  return welcomeMessage;
}

module.exports = {
  processMessage,
  generateMenuMessage
};
