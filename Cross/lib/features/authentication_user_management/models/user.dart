class User {
  final String _email;
  final String _password;
  final String _displayName;
  final String _dateOfBirth;
  final String _gender;

  User(
    this._email,
    this._password,
    this._displayName,
    this._dateOfBirth,
    this._gender,
  );

  String get email => _email;
  String get password => _password;
  String get displayName => _displayName;
  String get dateOfBirth => _dateOfBirth;
  String get gender => _gender;
}
