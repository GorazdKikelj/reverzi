from flask import Flask, render_template
import psycopg2
import psycopg2.extras
import json 
from flask import render_template, redirect, url_for, flash

reverz = Flask(__name__)

db = 'postgresql://gorazd:ruyagerakoc@localhost/gorazd'
conn = psycopg2.connect(db)
cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

@reverz.route('/home')
def home_page():
    return "<h1>To je home page</h1>"

@reverz.route('/')
def reverz_page():
#    cursor.execute('''select json_agg(reverz_list) from reverz_list;''')
#    json_data = cursor
#    print(json_data)
    cursor.execute('''select * from reverz_list;''')
    rev = cursor.fetchall()
    return render_template('reverz.html', reverzi=rev)

@reverz.route('/reverz', methods=['GET', 'POST'])
def izdaja_page(reverz_id):
    cursor.execute("select * from reverz_list where reverz = %s limit 1;" % reverz_id)
    cust = cursor.fetchone()
    if cust:
        cursor.execute("select * from reverz_details where reverz_id = %s;" % reverz_id)
        rev = cursor.fetchall()
        return render_template('izdaja_page', reverz_id=rev)
    else:
        flash(f'Reverz {reverz_id} ne obstaja')
        return render_template('home_page')
    
    

if __name__ == "__main__":
    reverz.run(debug=True, host="0.0.0.0") 

