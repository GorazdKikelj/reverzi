from flask import Flask, render_template, redirect
from flask_login import LoginManager, login_user, UserMixin, current_user, logout_user, login_required
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired, Length
import radius

RAD_HOST = "10.100.0.51"
RAD_SECRET = "ArubaDemo"
RAD_PORT = 1812

app_login = Flask(__name__)
app_login.config['SECRET_KEY'] = 'ec9ss9cfc6c796ae2029594d'
login_manager = LoginManager(app_login)
login_manager.login_view = "login_page"
login_manager.login_message_category = "info"
login_manager.session_protection = "strong"
login_manager.init_app(app_login)


#class UserModel():
#    username : str
#    password : str

#user = UserModel(username='gorazd',password='geslo')

class Users(UserMixin):
    username : str
    password : str

    def __repr__(self):
        return f'User {self.username}'

@login_manager.request_loader
def load_user(user_id):
    return Users.get(user_id)
   
class LoginForm(FlaskForm):
    username = StringField(label='Username:', validators=[Length(min=4,max=12),DataRequired()])
    password = PasswordField(label='Password:', validators=[Length(min=4,max=16),DataRequired()])
    submit = SubmitField(label='Log in')

@app_login.route('/')
def home_login():
    return render_template('home.html')

@app_login.route('/login')
def login_page():
    print('Forming login form')
    form = LoginForm()
    print('Rendering page')
    return render_template('login.html', form=form)


if __name__ == '__main__':
    print('Starting login app')
    app_login.run(debug=True,host='0.0.0.0',port=6000)
