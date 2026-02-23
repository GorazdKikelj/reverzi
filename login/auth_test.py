from flask import Flask, render_template, redirect, request, url_for, flash
from flask_login import (
    LoginManager,
    UserMixin,
    login_user,
    login_required,
    logout_user,
    current_user,
)
from radius import Radius

from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired, Length

RAD_HOST = "10.100.0.51"
RAD_SECRET = "ArubaDemo"
RAD_PORT = 1812

app = Flask(__name__)
app.config["SECRET_KEY"] = "123456"
login_manager = LoginManager()
login_manager.init_app(app)
rad = Radius(host=RAD_HOST, secret=RAD_SECRET, port=RAD_PORT)


@login_manager.user_loader
def load_user(user_id):
    return User.get(user_id)


@login_manager.request_loader
def request_loader(request):
    user = request.form.get("username")
    pswd = request.form.get("password")
    try:
        reply = Radius.authenticate(username=user, password=pswd)
    except Exception as e:
        return None
    if reply:
        user = User.get(user)
    return user


class User(UserMixin):
    def __init__(self, username):
        self.username = username

    def get_id(self):
        return self.username

    @staticmethod
    def authenticate(username, password):
        try:
            reply = rad.authenticate(username=username, password=password)
        except Exception as e:
            print(f"Radius error {e}")
            return None

        if reply:
            return User(username)
        else:
            return None

    @staticmethod
    def get(username):
        return User(username)


@app.route("/logout")
def logout_page():
    logout_user()
    return redirect(url_for("home"))


class LoginForm(FlaskForm):
    username = StringField(
        "Username", validators=[DataRequired(), Length(min=1, max=50)]
    )
    password = PasswordField("Password", validators=[DataRequired(), Length(min=4)])
    submit = SubmitField("Login")


@app.route("/login", methods=["GET", "POST"])
def login():
    if current_user.is_authenticated:
        print(f"User is authenticated {current_user}")
        return redirect(url_for("loggedin"))

    form = LoginForm()
    if request.method == "POST":
        if form.validate_on_submit():
            print(f"Authentication of user is in progress {form.username.data}")

            user = User.authenticate(
                username=form.username.data, password=form.password.data
            )

            print(f"Authentication of user is completed {user.username}")

            if user:
                login_user(user)
                return redirect(request.args.get("next") or url_for("loggedin"))

    return render_template("login.html", title="Login", form=form)


@app.route("/")
def home():
    return render_template("home.html")


@app.route("/loggedin")
@login_required
def loggedin():
    return render_template("loggedin.html")


# -------------------------------------------------------------------


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5001)
