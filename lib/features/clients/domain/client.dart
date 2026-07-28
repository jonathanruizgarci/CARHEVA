class Client {
  const Client({
    required this.id,
    required this.name,
    required this.createdBy,
    this.contact,
    this.notes,
  });

  final String id;
  final String name;
  final String? contact;
  final String? notes;
  final String createdBy;
}
