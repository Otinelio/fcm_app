MODULE 2 — Mettre en place le Presence Channel côté Reverb et Flutter

1. Objectif du module

Faire qu'un client Flutter rejoigne un presence channel personnel presence-customer.{id} dès qu'il ouvre l'app, et que ce channel soit authentifié correctement côté Laravel.

2. Concept à comprendre

Un presence channel est une variante du private channel qui garde en mémoire, côté serveur Reverb, la liste des connexions actives sur ce channel. C'est différent d'un simple private channel (qui sécurise juste l'accès) : la presence ajoute une notion de "qui est là en ce moment".

Pourquoi un channel par client (presence-customer.{id}) et pas un channel global ? Parce qu'on veut pouvoir interroger "est-ce que le client 42 est connecté" indépendamment des autres — un channel global mélangerait tout le monde et rendrait la vérification de présence individuelle impossible.

Le nom technique compte : côté HTTP API Reverb (qu'on utilisera au Module 3), seuls les channels préfixés presence- exposent une liste d'utilisateurs interrogeable.

3. Actions exactes à réaliser


Déclarer le channel customer.{customerId} comme presence channel dans routes/channels.php, en retournant un tableau de données utilisateur (pas juste true) — c'est ce qui le différencie d'un private channel.
Vérifier que le BroadcastServiceProvider est bien actif (déjà fait dans la formation Reverb, à confirmer).
Côté Flutter, rejoindre ce presence channel à l'ouverture de l'app, juste après l'authentification du client.
Logger côté Flutter les événements pusher:subscription_succeeded pour confirmer la jointure.


4. Fichiers à créer ou modifier


routes/channels.php
lib/services/realtime_service.dart (ou ton fichier existant de connexion Echo/Pusher créé dans la formation Reverb)


5. Commandes à exécuter

Aucune commande nouvelle — on modifie du code existant.

6. Code à écrire

routes/channels.php :

phpuse App\Models\Customer;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('customer.{customerId}', function ($user, int $customerId) {
    // Authentification : le client connecté doit être celui du channel
    if ((int) $user->id !== $customerId) {
        return false;
    }

    // Presence channel : on retourne un tableau de données (pas juste true/false)
    // C'est ce retour qui transforme le private channel en presence channel
    return [
        'id' => $user->id,
        'name' => $user->name,
    ];
});

Côté Flutter, dans ton service de connexion existant :

dartclass RealtimeService {
  late PusherChannelsFlutter pusher;

  Future<void> connectPresenceChannel(int customerId) async {
    await pusher.subscribe(
      channelName: 'presence-customer.$customerId',
      onSubscriptionSucceeded: (data) {
        // Confirme que la jointure au presence channel a réussi
        print('Presence channel rejoint pour customer $customerId');
      },
      onMemberAdded: (member) {
        print('Membre ajouté au presence channel: $member');
      },
      onEvent: (event) {
        _handleRealtimeEvent(event);
      },
    );
  }

  void _handleRealtimeEvent(PusherEvent event) {
    // Sera complété au Module 4 (réception du RewardUnlocked)
  }
}


Note : le préfixe presence- côté client correspond au préfixe private- que tu utilisais déjà pour les private channels — Reverb route automatiquement vers le bon type de channel selon ce préfixe, en cohérence avec ce que retourne ta closure dans channels.php.



7. Résultat attendu


Au lancement de l'app, le log Flutter affiche "Presence channel rejoint pour customer X".
Côté serveur, aucune erreur d'autorisation dans les logs Reverb.


8. Comment vérifier que ça fonctionne

Lance php artisan reverb:start --debug et observe les logs au moment où l'app Flutter se connecte : tu dois voir une requête d'autorisation réussie sur /broadcasting/auth pour le channel presence-customer.{id}, suivie d'une connexion établie.

9. Erreurs courantes à éviter


Retourner true au lieu d'un tableau dans la closure Broadcast::channel — ça transforme silencieusement ton presence channel en simple private channel (la vérification de présence du Module 3 renverra toujours une liste vide).
Oublier le préfixe presence- côté Flutter dans subscribe() alors que côté Laravel le nom du channel ne le porte pas — c'est normal, c'est Reverb qui ajoute ce préfixe au moment de l'authentification, mais le client doit le déclarer explicitement.
Rejoindre le channel avant que l'utilisateur soit authentifié (token absent) → échec d'autorisation silencieux.


10. Checklist de validation avant de passer au module suivant


 Le presence channel customer.{id} est déclaré et retourne un tableau, pas un booléen.
 Flutter rejoint bien presence-customer.{id} au démarrage de l'app, après authentification.
 Le log onSubscriptionSucceeded s'affiche à chaque lancement de l'app de test.
 Aucune erreur 403 dans les logs Reverb lors de la connexion.



MODULE 3 — Vérifier la présence d'un client côté serveur

1. Objectif du module

Créer un service Laravel PresenceChecker capable d'interroger Reverb depuis le backend pour savoir, à un instant donné, si un client donné a un socket actif sur son presence channel.

2. Concept à comprendre

Reverb est compatible avec le protocole Pusher, pas seulement côté WebSocket client mais aussi côté API HTTP serveur-à-serveur. Ça veut dire que tu peux utiliser le SDK officiel pusher/pusher-php-server, en le pointant vers l'hôte/port de ton serveur Reverb au lieu du vrai service Pusher, pour appeler des endpoints comme "liste des utilisateurs présents sur ce channel".

C'est une information que ton backend Laravel n'a normalement pas par lui-même (un event broadcasté part dans le vide, sans savoir qui écoute) — cette API HTTP est le seul pont qui te permet d'interroger l'état du serveur Reverb depuis du code PHP classique, en dehors d'un event broadcast.

Point important avec ton Nginx en place : Nginx route le trafic WebSocket public (port 80/443) vers Reverb sur le port 8080, pour les clients Flutter externes. Mais ici, c'est ton backend Laravel qui appelle Reverb — les deux tournent sur la même machine. Il n'y a aucune raison de faire sortir cet appel par Nginx puis revenir dessus : PresenceChecker doit pointer directement sur 127.0.0.1:8080 (l'adresse interne du process Reverb), pas sur le nom de domaine public. C'est plus rapide (pas de saut réseau supplémentaire) et ça continue de fonctionner même si Nginx est temporairement down pour une maintenance, alors que Reverb tourne toujours.

Pourquoi un service dédié et pas un appel direct dans le contrôleur ? Parce que cette vérification sera utilisée à plusieurs endroits (au moment du reward, mais potentiellement aussi pour les promos ou les rappels plus tard) — autant centraliser la logique d'appel à l'API Reverb une seule fois.

3. Actions exactes à réaliser


Installer le SDK Pusher PHP via Composer.
Récupérer dans .env les identifiants Reverb déjà configurés (REVERB_APP_KEY, REVERB_APP_SECRET, REVERB_APP_ID, host/port du serveur).
Créer app/Services/PresenceChecker.php qui instancie le client Pusher pointé vers Reverb.
Implémenter isCustomerOnline(int $customerId): bool qui interroge l'endpoint des utilisateurs du presence channel.
Tester manuellement ce service depuis php artisan tinker.


4. Fichiers à créer ou modifier


app/Services/PresenceChecker.php
.env (vérifier les clés existantes, aucune nouvelle clé nécessaire si Reverb est déjà configuré)


5. Commandes à exécuter

bashcomposer require pusher/pusher-php-server

6. Code à écrire

app/Services/PresenceChecker.php :

php<?php

namespace App\Services;

use Pusher\Pusher;
use Pusher\PusherException;
use Illuminate\Support\Facades\Log;

class PresenceChecker
{
    protected Pusher $pusher;

    public function __construct()
    {
        $this->pusher = new Pusher(
            config('reverb.apps.apps.0.key'),
            config('reverb.apps.apps.0.secret'),
            config('reverb.apps.apps.0.app_id'),
            [
                // Important : on pointe sur l'adresse INTERNE du process Reverb
                // (127.0.0.1:8080), pas sur le domaine public servi par Nginx.
                // Backend et Reverb tournent sur la même machine ici — aucune
                // raison de faire transiter cet appel serveur-à-serveur par
                // le reverse proxy, et ça reste fonctionnel même si Nginx
                // est temporairement indisponible.
                'host' => '127.0.0.1',
                'port' => config('reverb.servers.reverb.port', 8080),
                'scheme' => 'http',
                'useTLS' => false,
            ]
        );
    }

    /**
     * Interroge Reverb (via l'API compatible Pusher) pour savoir
     * si un client a un socket actif sur son presence channel personnel.
     */
    public function isCustomerOnline(int $customerId): bool
    {
        $channelName = "presence-customer.{$customerId}";

        try {
            $response = $this->pusher->get("/channels/{$channelName}/users");
            $decoded = json_decode($response, true);

            return ! empty($decoded['users']);
        } catch (PusherException $e) {
            // Si l'API Reverb est inaccessible, on considère le client absent
            // par sécurité : ça déclenchera le fallback FCM, ce qui est le
            // comportement le moins risqué (mieux vaut un push en trop
            // qu'un client jamais notifié).
            Log::warning('PresenceChecker: échec de vérification', [
                'customer_id' => $customerId,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }
}

Test rapide dans tinker :

bashphp artisan tinker
>>> app(\App\Services\PresenceChecker::class)->isCustomerOnline(1);

7. Résultat attendu


Avec l'app Flutter de test ouverte et connectée (Module 2 validé), isCustomerOnline(1) retourne true.
Avec l'app fermée, ça retourne false après quelques secondes (le temps que Reverb détecte la déconnexion du socket).


8. Comment vérifier que ça fonctionne

Ouvre l'app Flutter, lance la commande tinker → true. Ferme complètement l'app (kill du process, pas juste mise en arrière-plan), attends 5-10 secondes, relance la commande → false.

9. Erreurs courantes à éviter


Pointer PresenceChecker sur le domaine public (celui que Nginx sert) au lieu de 127.0.0.1:8080 — ça fonctionnera la plupart du temps, mais ça ajoute une dépendance inutile à Nginx pour un appel purement interne, et certaines configs Nginx strictes sur le routage WebSocket peuvent carrément rejeter cette requête HTTP classique (non-upgrade) sur le chemin prévu pour les WebSockets.
Utiliser les credentials du vrai Pusher (s'il y en a un dans le projet pour autre chose) au lieu de ceux de Reverb — vérifie bien que tu lis config('reverb.*') et pas config('broadcasting.connections.pusher.*').
Oublier le try/catch : si Reverb est down et que ce service plante sans être catché, ça fait tomber toute la chaîne de notification du reward, pas seulement la vérification de présence.
Croire que false après fermeture de l'app est instantané — il y a un délai de détection de déconnexion côté Reverb (normal, lié au heartbeat WebSocket), ne pas s'inquiéter si ça prend quelques secondes.


10. Checklist de validation avant de passer au module suivant


 composer require pusher/pusher-php-server installé sans erreur.
 PresenceChecker::isCustomerOnline() retourne true avec l'app ouverte.
 Le même appel retourne false quelques secondes après fermeture de l'app.
 Le try/catch est en place et loggue proprement en cas d'échec d'appel à Reverb.



MODULE 4 — Événement RewardUnlocked et diffusion Reverb

1. Objectif du module

Créer l'event RewardUnlocked, le déclencher quand un client atteint son palier de points, et le diffuser immédiatement sur son presence channel — sans encore se soucier du fallback FCM (ce sera le Module 6).

2. Concept à comprendre

On reprend ici exactement le mécanisme de la formation Reverb (event ShouldBroadcast), mais avec deux différences volontaires par rapport à un event "solde de points" classique :


On diffuse sur le presence channel créé au Module 2 (pas un private channel simple), parce qu'on aura besoin plus tard de vérifier qui est dessus.
L'event embarque un reward_id unique — c'est cet identifiant qui servira de clé pour l'ack et l'idempotence dans les modules suivants. Sans identifiant stable, impossible de savoir plus tard "est-ce que CE reward précis a été confirmé reçu".


À ce stade du guide, on diffuse "à l'aveugle" : qu'il y ait quelqu'un en écoute ou pas, l'event part. C'est voulu — c'est le point 1 du schéma du Module 1.

3. Actions exactes à réaliser


Créer la migration et le modèle Reward s'ils n'existent pas déjà dans ton projet (palier, client, statut débloqué).
Créer l'event RewardUnlocked implements ShouldBroadcast.
Déclencher l'event dans le service existant qui valide les stamps de fidélité, quand le palier est atteint.
Réceptionner l'event côté Flutter sur le presence channel et mettre à jour le solde affiché.


4. Fichiers à créer ou modifier


app/Events/RewardUnlocked.php
app/Services/LoyaltyService.php (ou l'équivalent existant qui gère la validation des stamps)
lib/services/realtime_service.dart (compléter _handleRealtimeEvent)


5. Commandes à exécuter

bashphp artisan make:event RewardUnlocked

6. Code à écrire

app/Events/RewardUnlocked.php :

php<?php

namespace App\Events;

use App\Models\Reward;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;

class RewardUnlocked implements ShouldBroadcast
{
    use Dispatchable;

    public function __construct(public Reward $reward)
    {
    }

    public function broadcastOn(): array
    {
        return [
            new PresenceChannel('customer.' . $this->reward->customer_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'reward.unlocked';
    }

    public function broadcastWith(): array
    {
        return [
            'reward_id' => $this->reward->id,
            'title' => $this->reward->title,
            'description' => $this->reward->description,
            'unlocked_at' => $this->reward->unlocked_at->toIso8601String(),
        ];
    }
}

Déclenchement dans le service de fidélité (extrait à intégrer dans ta méthode existante de validation de stamp) :

php// Dans LoyaltyService, après avoir détecté que le palier est atteint
$reward = Reward::create([
    'customer_id' => $customer->id,
    'title' => 'Dessert offert',
    'description' => 'Bravo, tu as débloqué un dessert gratuit !',
    'unlocked_at' => now(),
]);

event(new RewardUnlocked($reward));

Côté Flutter, compléter _handleRealtimeEvent :

dartvoid _handleRealtimeEvent(PusherEvent event) {
  if (event.eventName == 'reward.unlocked') {
    final data = jsonDecode(event.data);
    final rewardId = data['reward_id'];

    // Mise à jour immédiate de l'UI
    _showRewardBanner(data['title'], data['description']);
    _refreshLoyaltyBalance();

    // L'envoi de l'ack sera ajouté au Module 5
  }
}

7. Résultat attendu


En validant un stamp qui débloque un palier, une bannière apparaît instantanément dans l'app Flutter (app ouverte), sans aucun délai perceptible.
Une ligne reward_id cohérente apparaît dans les logs Reverb (--debug).


8. Comment vérifier que ça fonctionne

Avec l'app ouverte et le presence channel actif (Module 2), valide un stamp qui débloque un reward depuis le dashboard restaurant (ou Tinker). La bannière doit apparaître en moins d'une seconde, sans rafraîchir l'app.

9. Erreurs courantes à éviter


Diffuser sur un PrivateChannel au lieu d'un PresenceChannel — ça fonctionnera pour l'affichage, mais PresenceChecker (Module 3) ne trouvera jamais personne dessus, et tout le mécanisme de fallback déclenchera systématiquement un FCM inutile.
Oublier broadcastAs() et laisser le nom d'event par défaut (App\Events\RewardUnlocked) — Flutter doit écouter exactement le même nom (reward.unlocked).
Ne pas inclure reward_id dans broadcastWith() — sans cet identifiant, impossible de faire l'ack au module suivant.


10. Checklist de validation avant de passer au module suivant


 L'event RewardUnlocked diffuse bien sur PresenceChannel('customer.{id}').
 reward_id est présent dans le payload reçu côté Flutter.
 La bannière in-app s'affiche instantanément (app ouverte) sans refresh manuel.
 Le nom d'event reward.unlocked correspond exactement entre backend et Flutter.