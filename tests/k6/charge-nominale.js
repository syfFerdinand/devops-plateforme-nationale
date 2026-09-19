// Test de performance — seuils bloquants du pipeline (docs/02 §2).
// Exécuté chaque nuit en recette : détecte les régressions de latence avant la production.
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 50 },    // montée
    { duration: '5m', target: 200 },   // ~2x la charge nominale
    { duration: '3m', target: 200 },   // palier
    { duration: '2m', target: 0 },     // descente
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1500'],  // SLO de latence
    http_req_failed: ['rate<0.01'],                   // taux d'erreur < 1 %
    checks: ['rate>0.99'],
  },
};

const BASE = __ENV.BASE_URL || 'https://api.recette.plateforme.gouv';

export default function () {
  // Parcours usager critique : consultation puis soumission d'une demande.
  const profil = http.get(`${BASE}/api/v1/profil`, {
    headers: { Authorization: `Bearer ${__ENV.TOKEN}` },
    tags: { parcours: 'consultation' },
  });
  check(profil, { 'profil 200': (r) => r.status === 200 });

  sleep(1);

  const demande = http.post(
    `${BASE}/api/v1/demandes`,
    JSON.stringify({ type: 'attestation', reference: `k6-${__VU}-${__ITER}` }),
    {
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${__ENV.TOKEN}` },
      tags: { parcours: 'soumission' },
    },
  );
  check(demande, {
    'demande créée': (r) => r.status === 201,
    'latence acceptable': (r) => r.timings.duration < 800,
  });

  sleep(2);
}
