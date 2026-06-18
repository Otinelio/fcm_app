MODULE 12 — Segmentation

12.1 — Topics pour les segments larges et stables

🔧 Action côté Flutter (à appeler par exemple juste après le login, selon le statut du user reçu du backend) :

dartif (user.isVip) {
  await FirebaseMessaging.instance.subscribeToTopic('vip_customers');
}

🔧 Côté Laravel, l'envoi à tout le topic en une seule requête :

phpHttp::withToken($fcm->getAccessToken())->post($url, [
    'message' => [
        'topic' => 'vip_customers',
        'notification' => ['title' => 'Accès VIP', 'body' => 'Soirée privée ce vendredi'],
    ],
]);

12.2 — Requête DB pour les segments fins et dynamiques

🔧 Action — réutilise exactement le pattern du Module 9, juste avec une condition différente :

phpUser::where('last_visit_at', '<', now()->subDays(30))
    ->whereHas('deviceTokens')
    ->chunk(200, function ($users) {
        // dispatch SendPromoNotification pour chaque token
    });

✅ Résultat attendu : abonne un utilisateur de test au topic vip_customers, envoie au topic → il reçoit la notification ; un autre utilisateur non-abonné ne la reçoit pas.

⚠️ Erreur à éviter : utiliser des topics pour des segments qui changent souvent (ex: "actifs dans les 7 derniers jours") — les abonnements topic ne se mettent pas à jour seuls, il faudrait les recalculer et réabonner/désabonner constamment. Pour ce genre de segment, la requête DB (12.2) est la bonne approche.