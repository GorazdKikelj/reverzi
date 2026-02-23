from flask import Flask
from flask_login import (
    LoginManager,
    login_user,
    UserMixin,
    current_user,
    logout_user,
    login_required,
)
from flask_ckeditor import CKEditor
import psycopg2
import psycopg2.extras
import json
from datetime import datetime
from radius import Radius

app = Flask(__name__)
app.config["SECRET_KEY"] = "ec9439cfc6c796ae2029594d"

ckeditor = CKEditor(app)

DB_NAME = "gorazd"
DB_USER = "gorazd"
DB_PASS = "ruyagerakoc"
DB_HOST = "localhost"
DB_PORT = 5432

RAD_HOST = "10.100.0.41"
RAD_SECRET = "ArubaDemo"
RAD_PORT = 1812

login_manager = LoginManager()
login_manager.init_app(app)
rad = Radius(host=RAD_HOST, secret=RAD_SECRET, port=RAD_PORT)
login_manager.login_view = "login_page"
login_manager.login_message_category = "info"
login_manager.session_protection = "strong"

from reverz.logconfig import logger

logger.info("Reverzi startup -----")
with psycopg2.connect(
    dbname=DB_NAME, user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT
) as conn:
    cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cursor_list = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    from reverz import routes
