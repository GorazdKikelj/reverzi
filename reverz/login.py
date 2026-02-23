"""example 1

glej bolj auth.py in login.py
Tukaj so zelo generične procedure

Te rutine se ne uporabljajo v aplikaciji. So samo za test.
"""

from flask import Flask, render_template, redirect
from flask_login import (
    LoginManager,
    login_user,
    UserMixin,
    current_user,
    logout_user,
    login_required,
)
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired, Length
import radius
import pyrad

RAD_HOST = "10.100.0.41"
RAD_SECRET = "ArubaDemo"
RAD_PORT = 1812

app_login = Flask(__name__)
app_login.config["SECRET_KEY"] = "ec9ss9cfc6c796ae2029594d"
login_manager = LoginManager(app_login)
login_manager.login_view = "login_page"
login_manager.login_message_category = "info"
login_manager.session_protection = "strong"
login_manager.init_app(app_login)


# class UserModel():
#    username : str
#    password : str

# user = UserModel(username='gorazd',password='geslo')


class Users(UserMixin):
    username: str
    password: str

    def __repr__(self):
        return f"User {self.username}"


@login_manager.request_loader
def load_user(user_id):
    return Users.get(user_id)


class LoginForm(FlaskForm):
    username = StringField(
        label="Username:", validators=[Length(min=4, max=12), DataRequired()]
    )
    password = PasswordField(
        label="Password:", validators=[Length(min=4, max=16), DataRequired()]
    )
    submit = SubmitField(label="Log in")


@app_login.route("/")
def home_login():
    return render_template("home.html")


@app_login.route("/login")
def login_page():
    form = LoginForm()
    return render_template("login.html", form=form)


if __name__ == "__main__":
    app_login.run(debug=True, host="0.0.0.0", port=6000)

""" Example 2"""
from flask import Flask, render_template, request, redirect, url_for
from flask_login import (
    LoginManager,
    login_user,
    current_user,
    logout_user,
    login_required,
)
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired
from pyrad.client import Client
from pyrad.dictionary import Dictionary

app = Flask(__name__)
app.config["SECRET_KEY"] = "secret key"
login_manager = LoginManager(app)
login_manager.login_view = "login"


class LofinForm(FlaskForm):
    username = StringField(label="Username", validators="[DataRequired()]")
    password = PasswordField(label="Password", validators="[DataRequired()]")
    submit = SubmitField(label="Login")


@login_manager.user_loader
def load_user(user_id):
    return User.get(user_id)


@app.route("/login", methods=["GET", "POST"])
def login():
    if current_user.is_authenticated:
        return redirect(url_for("index"))
    form = LoginForm()
    if form.validate_on_submit():
        username = form.username.data
        password = form.password.data
        client = Client(
            server=RAD_HOST, secret=RAD_SECRET, dict=Dictionary("dictionary_file")
        )
        result = client.authenticate(username, password)
        if result:
            user = load_user(username)
            if user is None:
                user = User(username)
                save_user(user)
            login_user(user)
            flash("Logged in successfully")
            return redirect(url_for("index"))
        else:
            flash("Invalid password")
    return render_template("login.html", form=form)


@app.route("/logout")
def logout():
    logout_user()
    return redirect(url_for("index"))
