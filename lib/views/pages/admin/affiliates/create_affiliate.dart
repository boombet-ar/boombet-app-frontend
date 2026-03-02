import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/affiliates_service.dart';
import 'package:flutter/material.dart';

Future<void> showCreateAffiliateDialog({
  required BuildContext context,
  required AfiliadoresService service,
  required VoidCallback onCreated,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final nameController = TextEditingController();
  final affiliateTokenController = TextEditingController();

  try {
    bool isSubmitting = false;
    String? selectedType;
    final availableTypes = await service.fetchAfiliadorTipos();

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> handleSubmit() async {
              if (isSubmitting) return;

              if (selectedType == null || selectedType!.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Seleccioná un tipo para continuar.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              final isEvento = selectedType!.toUpperCase() == 'EVENTO';
              final nombre = nameController.text.trim();
              final affiliateToken = affiliateTokenController.text.trim();

              if (nombre.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Completá el nombre para continuar.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              try {
                setState(() {
                  isSubmitting = true;
                });

                await service.createAfiliador(
                  nombre: nombre,
                  tipoAfiliador: selectedType!,
                  email: null,
                  dni: null,
                  telefono: null,
                  tokenAfiliador: isEvento && affiliateToken.isNotEmpty
                      ? affiliateToken
                      : null,
                );

                if (dialogContext.mounted &&
                    Navigator.of(dialogContext).canPop()) {
                  Navigator.pop(dialogContext);
                }

                onCreated();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Afiliador creado correctamente.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (dialogContext.mounted) {
                  setState(() {
                    isSubmitting = false;
                  });
                }

                final rawError = e.toString().toLowerCase();
                final isDuplicateCodeError =
                    rawError.contains('409') ||
                    rawError.contains('duplicate') ||
                    rawError.contains('duplicado') ||
                    rawError.contains('already exists') ||
                    rawError.contains('ya existe') ||
                    rawError.contains('token_afiliador') ||
                    rawError.contains('codigo') ||
                    rawError.contains('código') ||
                    rawError.contains('unique');

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      isDuplicateCodeError
                          ? 'El código de afiliador ya existe. Usá otro código.'
                          : 'No se pudo crear el afiliador.',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }

            return _buildCreateAffiliateDialog(
              context: dialogContext,
              availableTypes: availableTypes,
              selectedType: selectedType,
              onTypeChanged: (value) {
                setState(() {
                  selectedType = value;
                });
              },
              nameController: nameController,
              affiliateTokenController: affiliateTokenController,
              onSubmit: handleSubmit,
              isSubmitting: isSubmitting,
            );
          },
        );
      },
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('No se pudieron cargar los tipos de afiliador.'),
        duration: Duration(seconds: 2),
      ),
    );
  } finally {
    Future.delayed(const Duration(milliseconds: 200), () {
      nameController.dispose();
      affiliateTokenController.dispose();
    });
  }
}

Widget _buildCreateAffiliateDialog({
  required BuildContext context,
  required List<String> availableTypes,
  required String? selectedType,
  required ValueChanged<String?> onTypeChanged,
  required TextEditingController nameController,
  required TextEditingController affiliateTokenController,
  required VoidCallback onSubmit,
  required bool isSubmitting,
}) {
  final theme = Theme.of(context);
  final textColor = AppConstants.textDark;
  final accent = theme.colorScheme.primary;
  const dialogBg = AppConstants.darkAccent;

  return Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    backgroundColor: dialogBg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius + 6),
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.25),
                  accent.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadius + 6),
                topRight: Radius.circular(AppConstants.borderRadius + 6),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(Icons.person_add_alt_1, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crear afiliador',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Seleccioná el tipo. Los campos se mostrarán según el tipo elegido.',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      hintText: 'Seleccionar tipo',
                    ),
                    items: availableTypes
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    onChanged: onTypeChanged,
                  ),
                  if (selectedType != null && selectedType.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ingresá el nombre',
                      ),
                    ),
                  ],
                  if (selectedType?.toUpperCase() == 'EVENTO') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: affiliateTokenController,
                      decoration: InputDecoration(
                        labelText: 'Código de afiliador',
                        hintText: 'Ingresá el código de afiliador',
                        suffixIcon: IconButton(
                          tooltip: 'Ayuda',
                          icon: const Icon(Icons.help_outline),
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (helpContext) => AlertDialog(
                                title: const Text('Código de afiliador'),
                                content: const Text(
                                  'Al dejar este campo vacio, el codigo se creara automaticamente. En caso de querer asignar un codigo personalizado, ingresalo en este campo. El codigo debe ser unico y no puede ser modificado luego de la creación.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(helpContext),
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: AppConstants.textLight,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppConstants.textLight,
                            ),
                          )
                        : const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
