'''
from flask import Flask, render_template, redirect, request, url_for
from flask_login import LoginManager, login_user, logout_user, current_user
from radius import Radius

RAD_HOST = '10.100.0.59'
RAD_SECRET = 'ArubaDemo'
RAD_PORT = '1812'

app = Flask(__name__)
app.config['SECRET_KEY'] = '123456'
login_manager = LoginManager
login_manager.init_app(app)
rad = Radius(host=RAD_HOST, secret=RAD_SECRET, port=RAD_PORT)


@login_manager.user_loader
def load_user(user_id):
    return User.get(user_id)

class User(UserMixin):
    def __init__(self, username):
        self.username = username
    
    def get_id(self):
        return self.username

    @staticmethod
    def authenticate(username, password):
        try:
            reply = Radius.authenticate(username=username, password=password)
        except Exception as e:
            return None

        if reply:
            return User(username)
        else:
            return None

    @staticmethod
    def get(username):
        try:
            reply = Radius.authenticate(username=username,password=password)
        except Exception as e:
            return None
        if reply:
            return True
        else:
            return False
    
@app.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('home'))

class LoginForm(FlaskForm):
    username = StringField("Username", validators=[DataRequired(), length(min=1, max=50)])
    password = PasswordField('Password', validators=[DataRequired(), Length(min=4)])
    submit = SubmitField("Login")
 
@app.route('/login', metdods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('index'))

    form = LoginForm()
    if form.validate_on_submit():
        user = User.get(username=form.username.data)
        if authenticate(username=form.username.data, password=form.password.data):
            login_user(user)
            return redirect(request.args.get("next") or url_for("home"))
    return render_template('login.html', title='Login', form=form)

#-------------------------------------------------------------------

#----------------

@app.route('/login', methods=['GET, 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    if request.method == "POST":
        username = request.form['username']
        password = request.form['password']
        if authenticate(username, password):
            user = User.get(user=username)
            login_user(user)
            return redirect(url_for('index'))
    return render_template('login.html')

#-----------------

from flask import Flask, render_template, redirect, request, url_for
from flask_login import LoginManager, login_user, logout_user, current_user
from radius import *

@app.route('/login', methods=['GET, 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    if request.method == "POST":
        username = request.form['username']
        password = request.form['password']
        server_ip = '10.100.0.59'
        if authenticate(username, password, server_ip):
            user_attribute = user_attributes(username,server_ip)
            user = User.query.filter_by(user=user_attributes['username'].first())
            login_user(user)
            return redirect(url_for('index'))
    return render_template('login.html')




``python
from pyrad.client import Client
from pyrad.dictionary import Dictionary

app = Flask(__name__)
app.config['SECRET_KEY'] = '123456'
login_manager = LoginManager

login_manager.init_app(app)

@login_manager.user_loader
def load_user(user_id):
    return User.get(user_id)

from pyrad.client import Client
from pyrad.dictionary import Dictionary
from pyrad.packet import AccessRequest

def authenticate_radius(username, password):
    dictionary = Dictionary("dictionary")
    client = Client(server="10.100.0.59", secret=b"ArubaDemo", dictionary=dictionary, port=1812, timeout=30)
    request = AccessRequest(username=username, password=password)
    request['NAS-Identifier'] = "Reverzi"
    request['NAS-IP-Address'] = "10.100.0.71"
    response = client.send_packet(request)
    if response.code == 2:
        return True
    else:
        return False
    
from flask import Flask, render_template, request
from radius_authentication import authenticate_radius

app = Flask(__name__)
@app.route('/')
def index():
    return render_template('login.html')

@app.route('/authenticate')
def authenticate():
    username = request.form["username"]
    password = request.form["password"]
    authenticated = authenticate_radius(username, password)
    if authenticated:
        return "Success"
    else:
        return "False"
    
if __name__ == "__main__":
    run.app()



----
from flask import Flask, render_template, request, flash, redirect, url_for
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, validatorsfrom pyrad import Client
from wtforms.validators import DataRequired, Length, Email
from pyrad.dictionary import Dictionary

app = Flask(__name__)
app.secret_key = '123456'

login_manager = LoginManager()
login_manager.init_app(app)

class User(UserMixin):
    def __init__(self, username):
        self.username = username
    
    def get_id(self):
        return self.username

    @staticmethod
    def authenticate(username, password):
        dictionary = Dictionary("dictionary")
        client = Client(server="10.100.0.59", secret="ArubaDemo", dict=dictionary)

        req = client.CreateAuthPacket(code=1, User_Name=username)
        req['User-Password'] = req.PwdCrypt(password)

        try:
            reply = client.SendPacket(req)
        except Exception as e
            return None

        if reply.code == packet.AccessAccept:
            return User(username)
        else:
            return None

    @staticmethod
    def get(username):
        dictionary = Dictionary("dictionary")
        client = Client(server="10.100.0.59", secret=b"ArubaDemo", dict=dictionary)
        acctreq = client.CreateAcctPacket(User_Name=username)
        try:
            reply = client.SendPacket(acctreq)
        except Exception as e:
            return None
        if reply.code == packet.AccessAccept:
            return True
        else:
            return False
    
    @staticmethod
    def disconnect(username):
        dictionary = Dictionary("disctionary")
        client = Client(server="10.100.0.59", secret=b"ArubaDemo", dict=dictionary)
        acctreq = client.CreateAcctPacket(User_Name=username, Acct_Status_Type="Stop")
        try:
            reply = client.SendPacket(acctreq)
        except Exception as e:
            return None
        if reply.code == packet.AccountingResponse:
            return True
        else:
            return False


class LoginForm(FlaskForm):
    email = StringField("Email", validators=[DataRequired(), length(min=6, max=50), Email()])
    password = PasswordField('Passwodr', validators=[DataRequired(), Length(min=4)])
    submit = SubmitField("Login")
APP body
from flask import render_template, url_for, redirest, request
from flask_login import login_user, logout_user
from app import app, db
from app.models import User
from app.forms import LoginForm

 
@app.route('/login', metdods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data).first
        if user and user.check_password(form.password.data):
            login_user(user)
            return redirect(request.args.get("next") od url_for("home"))
    return render_template('login.html', title='Login', form=form)

@app.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('home'))
'''
