'''
Zamenjati tale del v header.html

                {% set id_req = request.path|replace('/','#') %}
                {% set url = url_for('help_page', id=id_req) %}

                <a class="btn" href="{{url}}" name="help" title="Pomoč na strani">
                    <i class="bi bi-question-lg"></i>
                </a>
                
z nekaj podobnega, kot je tole:

                <button data-id='{{id_req}}' class="helptext btn btn-success">Help</button></td>

Dodati javascript za dinamični zajem podatkov:

            <script type='text/javascript'>
            $(document).ready(function(){
                $('.url').click(function(){
                    var id = $(this).data('id');
                    $.ajax({
                        url: '/ajaxfile',
                        type: 'post',
                        data: {id: id},
                        success: function(data){ 
                            $('.modal-body').html(data); 
                            $('.modal-body').append(data.htmlresponse);
                            $('#empModal').modal('show'); 
                        }
                    });
                });
            });
            </script>
            
        <div class="modal fade" id="empModal" role="dialog">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h4 class="modal-title">Help text za stran {{stran}}</h4>
                          <button type="button" class="close" data-dismiss="modal">×</button>
                        </div>
                        <div class="modal-body">
                        </div>
                        <div class="modal-footer">
                          <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
        </div>
  
  
AJAX page za zajem podatkov:

//templates/response.html
{% for row in page %} 
<table border='0' width='100%'>
    <tr>
        <td width="300"><pre>{{row.help_entry}}</pre>
        </td>
    </tr>
</table>
{% endfor %}    

Novi ROUTE za zajem podatkov. 
Spremeniti je treba malo help_page route, da vrne modal vsebino.

@app.route("/ajaxfile",methods=["POST","GET"])
def ajaxfile():
    cur = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    if request.method == 'POST':
        userid = request.form['userid']
        print(userid)
        cur.execute("SELECT * FROM employee WHERE id = %s", [userid])
        employeelist = cur.fetchall() 
    return jsonify({'htmlresponse': render_template('response.html',employeelist=employeelist)})
    
    
Nekaj podobnega, kot tole:
@app.route("/ajaxfile", methods=["GET", "POST"])
def ajaxfile():
    """
    Redirect to help page.

    @param id - id of page to redirect to.

    @return success or failure of help
    """
    id = request.form['id']
    (status, page) = help_page_db(help_make_key(id=id))

    return jsonify('{htmlresponse': render_template('response.html',page=page)})
'''
