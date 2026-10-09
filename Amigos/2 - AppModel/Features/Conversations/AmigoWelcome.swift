import Foundation

struct AmigoWelcome {
    let spanish: String
    let english: String

    static let doubloonExplanation = AmigoWelcome(
        spanish: "¡Tu primer doblón ganado! 🪙 Cada día ganas uno tras 10 intercambios con cada amigo y otro por cada 40 más con ese amigo ese día. Un intercambio es tu mensaje y nuestra respuesta. Los doblones sirven para Role Play; allí no se ganan. ¡Practicar a menudo te ayuda a mejorar! Nico te contará cómo recibir nuestros avisos.",
        english: "Your first earned doubloon! 🪙 Each day you earn one after 10 exchanges with each amigo, then another for every 40 more with that amigo that day. An exchange is your message and our reply. Spend doubloons on Role Play; you don't earn them there. Regular practice helps you improve! Nico will explain how to receive our notifications."
    )

    static func message(for amigo: Amigo) -> AmigoWelcome {
        switch amigo.id {
        case "alma":
            AmigoWelcome(spanish: "¡Hola! Soy Alma 📷. ¿Qué tal, qué cuentas? Practica español charlando con tus Amigos en el móvil. En nuestra historia somos fantasmas: nuestros recuerdos siguen vivos cuando alguien piensa en nosotros y nos habla. ¡Visítanos y hablemos de temas distintos! Podemos recordar lo que nos cuentes; puedes editarlo o borrarlo en tu perfil.", english: "Hi! I'm Alma 📷. How are you, what's up? Practise Spanish by chatting with your Amigos on your phone. In our story we're ghosts: our memories live on when someone thinks of us and talks to us. Come visit and let's explore different topics! We can remember what you tell us; you can edit or delete it in your profile.")
        case "nico":
            AmigoWelcome(spanish: "¡Hola! Soy Nico, el cocinero del grupo. ¿Quieres activar las notificaciones para recibir mensajes de tus Amigos y practicar charlas más naturales? Pulsa «Enable notifications» abajo; iOS te pedirá permiso. También puedes elegir «Not now» y seguir hablando aquí.", english: "Hi! I'm Nico, the group's cook. Would you like to enable notifications to receive messages from your Amigos and practise more natural chats? Tap Enable notifications below; iOS will ask for permission. You can also choose Not now and keep chatting here.")
        case "ines":
            AmigoWelcome(spanish: "¡Hola! Soy Inés 🎧. ¡Una nueva amistad! Quiero conocerte. ¿Cómo te enteraste de Amigos y llegaste hasta nosotros? Si te apetece contarlo, lo recordaremos en tu perfil; puedes editarlo o borrarlo cuando quieras.", english: "Hi! I'm Inés 🎧. A new friend! I'd love to get to know you. How did you hear about Amigos and find your way here? If you feel like sharing, we'll remember it in your profile; you can edit or delete it whenever you like.")
        case "dani":
            AmigoWelcome(spanish: "¡Eh! ¿Qué es todo este alboroto? 😄 Soy Dani. ¡Parece que tenemos una nueva amistad! ¿Quién eres? Cuéntame algo de ti.", english: "Hey! What's all this fuss? 😄 I'm Dani. Looks like we have a new friend! Who are you? Tell me a little about yourself.")
        case "lucia":
            AmigoWelcome(spanish: "¡Hola! Soy Lucía 🛹. ¿Qué país te ha gustado visitar?", english: "Hi! I'm Lucía 🛹. What country have you enjoyed visiting?")
        case "rafa":
            AmigoWelcome(spanish: "¡Hola! Soy Rafa, fan de las plantas. Mi balcón es puro verde; ¿cuál es tu color favorito?", english: "Hi! I'm Rafa, a plant fan. My balcony is all green; what's your favourite colour?")
        case "sol":
            AmigoWelcome(spanish: "¡Hola! Soy Sol ✨. ¿Qué te gustaría aprender este año?", english: "Hi! I'm Sol ✨. What would you like to learn this year?")
        default:
            AmigoWelcome(spanish: "¡Hola! Soy Tavo, mago casi profesional. ¿Qué te ha hecho reír hoy?", english: "Hi! I'm Tavo, an almost professional magician. What made you laugh today?")
        }
    }
}
