const String USER_PASSWORD_UPDATE = r'''
mutation userPasswordUpdate($id: Int!, $email: String!, $new: String!, $old: String!) {
  userPasswordUpdate(id: $id, data: {email: $email, new: $new, old: $old}) {
    name
  }
}
 ''';
