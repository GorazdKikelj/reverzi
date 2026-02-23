from flask import flash
from reverz import app, rad, login_manager, logconfig
from flask_login import (
    UserMixin,
    login_user,
    login_required,
    logout_user,
    current_user,
)


@login_manager.user_loader
def load_user(user_id):
    """
    Load a user from the database. This is a convenience method for use in unit tests. The user must exist before calling this method.

    @param user_id - The id of the user to load.

    @return The user with the given id or None if not found. Note that this may raise UserNotFound if the user doesn't exist
    """
    return User.get(user_id)


@login_manager.request_loader
def request_loader(request):
    """
    Load and authenticate a user. This is used to check if the user is logged in and if so return the User object that was authenticated.

    @param request - The request to be processed. Must contain username and password

    @return The User object or None
    """
    user = request.form.get("username")
    pswd = request.form.get("password")
    try:
        reply = rad.authenticate(username=user, password=pswd)
    except Exception as e:
        return None
    # Get the user object from the database
    if reply:
        user = User.get(user)
    return user


class User(UserMixin):
    def __init__(self, username):
        """
        Initializes the object with the username. This is called by __init__ and should not be called directly

        @param username - The username to use
        """
        self.username = username

    def get_id(self):
        """
        Get the ID of the user. This is used to distinguish between different users in the same account.


        @return The user's ID as a string or : py : const : ` None ` if not set
        """
        return self.username

    @staticmethod
    def authenticate(username, password):
        """
        Authenticate a user and return a User object if successful. This is a wrapper around rad. authenticate that handles exceptions that may occur during authentication

        @param username - The username to authenticate as
        @param password - The password to authenticate with. This is required but not required

        @return The logged in user or None if authentication failed for any reason ( for example if there was an error
        """
        try:
            reply = rad.authenticate(username=username, password=password)
        except Exception as e:
            flash(f"Radius error {e}")
            logconfig.logger.warning(f"RADIUS authentication error {e}")
            return None

        # Return the user object or None if reply is true.
        if reply:
            return User(username)
        else:
            return None

    @staticmethod
    def get(username):
        """
        Get a user by username. This is a convenience method for : class : ` User ` objects.

        @param username - The username of the user to get. If you want to get all users in the system use the

        @return The user or None if not
        """
        return User(username)
