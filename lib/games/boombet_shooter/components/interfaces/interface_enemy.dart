/// Contrato mínimo para enemigos: recibir daño y reportar score.
abstract class IEnemy {
  void takeDamage(int amount);
  int getScoreValue();
}
