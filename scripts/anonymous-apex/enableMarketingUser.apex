final List<User> usersActive = [
        SELECT Id, UserPermissionsMarketingUser
        FROM User
        WHERE IsActive = TRUE AND Profile.UserLicense.Name = 'Salesforce' AND UserPermissionsMarketingUser = FALSE AND Alias != 'sagent'];
for (User u : usersActive) {
    u.UserPermissionsMarketingUser = true;
}
update usersActive;