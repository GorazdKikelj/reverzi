from reverz import app, DB_HOST, DB_NAME, DB_PORT, DB_USER, DB_PASS
from flask import render_template, redirect, url_for, flash, request, jsonify
from reverz.forms import (
    IzdajaForm,
    CustomerForm,
    CategoryForm,
    PersonForm,
    DemopoolForm,
    ProductForm,
    EmployeeForm,
    ReverzCreateForm,
    ReverzSelectForm,
    InventoryForm,
    reverz_items_add,
    ReverzEditItemForm,
    ReverzEditForm,
    ReverzCloseForm,
    LoginForm,
    HelpForm,
    reverz_items_add,
    reverz_set_items_field,
    InventorySearchForm,
)

from datetime import date, timedelta
from reverz.db_queries import *
from reverz.db_backup import backup_db
from reverz.auth import *
from reverz.logconfig import logger

"""
routes.py

Author: Gorazd Kikelj
Version: 0.1
Date: 25-MAR-2023

"""
"""
Home page 

routes: /
        /home

Seznam vseh reverzov od najnovejšega do najstarejšega.
Možnost izpisa za tiskalnik in pregleda 
        
List all demo loans from latest to oldest.
Loan can be printed or viewed.

Search and sort by by:

Status      True - active loan
            False - closed loan

Customer
Customer's person responsible for loan
Person approved loan

"""


@app.route("/")
@app.route("/home")
@app.route("/home/<limit>")
@login_required
def home_page(limit=0):
    """
    Render reverz list page.


    @return A template that renders the home page
    """
    (status, rev) = reverz_list() if not limit else reverz_list(limit=1)

    if not status:
        flash("Unable to load reverz list", category="danger")
        return redirect(url_for("home_page"))
    return render_template("home.html", reverzi=rev, datum_now=str(date.today()))


@app.route("/search")
@login_required
def search_page():
    """
    Display search page for inventory long list


    @return redirect to search page if
    """
    (status, rev) = inventory_long_list()
    if not status:
        flash("Unable to load inventory long list", category="danger")
        return redirect(url_for("search_page"))

    return render_template("search.html", reverzi=rev, datum_now=str(date.today()))


"""
Reverz

routes: /reverz
        /reverz/<id>
        /reverz/add
        /reverz/add/<id>
        /reverd/add/item/<id>
        /reverz/view/<id>
        /reverz/print/<id>
        
reverz_add_page()

"""


@app.route("/reverz/add", methods=["GET", "POST"])
@login_required
def reverz_add_page():
    """
     Add / select page for reverz. It is called via ajax and returns html to add / select a reverz.


     @return html to add / select

    reverz_add_page()
    route /reverz/add

    Doda novi reverz.
    Kliče se iz /reverz

    request.method = POST:
    Pripravi seznam zaposlenih pri stranki.
    Pripravi seznam zaposlenih v Selectium.
    Stran items.html

    """
    reverz_form = ReverzSelectForm()
    if request.method == "POST":

        class ItemsForm(ReverzCreateForm):
            pass

            def getField(self, fieldName):
                """
                Returns the field with the given name

                @param fieldName - Name of the field to return

                @return Field or None if not
                """
                for f in self:
                    if f.name in str(fieldName):
                        return f
                return None

        customer_id = request.form.get("id")
        (status, inventory) = inventory_active()

        if not status or not inventory:
            flash("Unable to load active inventory", category="danger")
            return redirect(url_for("reverz_page"))
        (status, customer) = customer_single(id=customer_id)
        reverz_set_items_field(
            items_form=ItemsForm, item_name_list=reverz_items_add(inventory)
        )
        reverz_frm = ItemsForm()

        (status, reverz_frm.customer_person_id.choices) = load_employee(customer_id)
        if not status:
            flash("Unable to load employee list", category="danger")
            return redirect(url_for("reverz_page"))
        reverz_frm.person_id.default = 1
        (status, reverz_frm.person_id.choices) = load_employee(1)
        if not status:
            flash("Unable to load Selectium Employees", category="danger")
            return redirect(url_for("reverz_page"))
        reverz_frm.demo_start_date.default = date.today()
        reverz_frm.demo_end_date.default = date.today() + timedelta(days=14)
        reverz_frm.active.default = True
        reverz_frm.process()
        return render_template(
            "items.html",
            reverz_form=reverz_frm,
            customer_id=customer_id,
            inventory=inventory,
            customer=customer["Name"],
        )

    return redirect(url_for("reverz_page"))


#
#
@app.route("/reverz/add/<id>", methods=["GET", "POST"])
@login_required
def reverz_add_new_page(id):
    """
    Add new reverz page.

    @param id - Id of customer to add.

    @return Redirect to reverz page
    """
    """reverz_add_new_page(id)
    route /reverz/add/<id>

    <id> customer_id

    zapiše novi reverz v bazo in doda vse izbrane inventarne številke
    v tabelo transakcij.

    """
    if request.method == "POST":
        (status, e) = reverz_insert(customer_id=id, request_form=request.form)
        if status:
            flash(f"Reverz addedd sucessfully. Status: {e}", category="success")
        else:
            flash(
                f"Error reverz customer. Rolling back changes. Error: {e}",
                category="danger",
            )
    return redirect(url_for("reverz_page"))


#
#
@app.route("/reverz/add/item/<id>", methods=["GET", "POST"])
@login_required
def reverz_add_item(id):
    """
    reverz_add_item(id)
    route: /reverz/add/item/<id>

    <id> številka reverza

    request.method:
        POST: kreira in napolni formo ReverzCreateForm(). Stran items.html
        GET: zapiše nove postavke v tabelo transakcij
    """

    if request.method == "GET":

        class ItemsForm(ReverzCreateForm):
            pass

            def getField(self, fieldName):
                """
                Returns the field with the given name

                @param fieldName - Name of the field to return

                @return Field or None if not
                """
                for f in self:
                    if f.name in str(fieldName):
                        return f
                return None

        (status, inventory) = reverz_list_single(id=id)
        if not status or not len(inventory):
            flash(f"Unable to load reverz {id}", category="danger")
            return redirect(url_for("reverz_page"))

        (status, inventory_list) = inventory_active()
        if not status or not len(inventory_list):
            flash(f"No available demo items", category="danger")
            return redirect(url_for("reverz_page"))

        reverz_set_items_field(
            items_form=ItemsForm, item_name_list=reverz_items_add(inventory_list)
        )
        rev_form = ItemsForm()
        rev_form.customer_person_id.default = inventory["customer_person_id"]
        rev_form.customer_person_id.choices = [
            (inventory["customer_person_id"], inventory["prevzel"])
        ]
        rev_form.person_id.default = inventory["person_id"]
        rev_form.person_id.choices = [(inventory["person_id"], inventory["izdal"])]
        rev_form.description.default = inventory["namen_testiranja"]
        rev_form.demo_start_date.default = inventory["datum_izdaje"]
        rev_form.demo_end_date.default = inventory["cas_testiranja_do"]
        rev_form.active.default = inventory["aktiven"]
        rev_form.process()

        return render_template(
            "items.html",
            reverz_form=rev_form,
            customer_id=inventory["customer_id"],
            inventory=inventory_list,
            id=inventory["reverz"],
            customer=inventory["stranka"],
        )

    if request.method == "POST":
        (status, e) = reverz_add_items(id=id, request_form=request.form)
        if status:
            flash(f"Reverz items addedd sucessfully. Status: {e}", category="success")
        else:
            flash(
                f"Error adding reverz items. Rolling back changes. Error: {e}",
                category="danger",
            )

    return redirect(url_for("reverz_edit", id=id))


#
# Print reverz from list or by entering reverz id
@app.route("/reverz/view/<id>", methods={"GET", "POST"}, endpoint="reverz-view")
@app.route("/reverz/print/<id>", methods={"GET", "POST"})
@login_required
def reverz_print_page(id=0):
    """
    reverz_print_page(id)
    route:  /reverz/view/<id>
            /reverz/print/<id>

    <id> številka reverza

    view: izpiše reverz na ekran čez celo stran
    print: izpiše reverz na A4 in razdeli tabelo po straneh.

    """

    izdaja_id = id
    (status, cust) = reverz_list_single(id=izdaja_id)
    if not status:
        flash(f"Reverz {izdaja_id} ne obstaja", category="danger")
    else:
        if "reverz/view" in request.path:
            url = "view.html"
            no_search = False
            (status1, rev) = reverz_detail_single_archive(id=izdaja_id)
        else:
            url = "print.html"
            no_search = True
            (status1, rev) = reverz_detail_single(id=izdaja_id)
        if status1:
            return render_template(
                url,
                customer_data=cust,
                reverz_data=rev,
                datum_now=date.today(),
                no_search=no_search,
            )
        flash(f"Napaka pri branju  podatkov za reverz {izdaja_id}", category="danger")
    return redirect(url_for("home_page"))


#
#
@app.route("/reverz", methods=["GET", "POST"])
@app.route("/reverz/<id>", methods=["GET", "POST"], endpoint="reverz-print")
@login_required
def reverz_page(id=0):
    """
    reverz_page(id=0)
    route:  /reverz
            /reverz/<id>


    <id> številka reverza

    <id> == 0 forma za vnos novega reverza. Stran izdaja.html
    <id> > 0  izpiše obstoječi reverz. Stran print.html
    """

    reverz_form = ReverzSelectForm()
    (status, reverz_form.id.choices) = load_customer()
    if not status:
        flash("Unable to load customer list", category="danger")
        return redirect(url_for("reverz_page"))
    izdaja_form = IzdajaForm()
    izdaja_id = id
    if request.method == "POST":
        izdaja_id = request.form.get("reverz_id")
    if izdaja_id == 0:
        (status, rev) = reverz_list()
        if not status:
            flash("Unable to load reverz list", category="danger")
            return redirect(url_for("reverz_page"))
        return render_template(
            "izdaja.html",
            reverzi=rev,
            datum_now=str(date.today()),
            izdaja_form=izdaja_form,
            reverz_form=reverz_form,
        )
    (status, cust) = reverz_list_single(id=izdaja_id)
    if status and cust:
        (status1, rev) = reverz_detail_single(id=izdaja_id)
        if not status1:
            flash(f"Unable to load reverz {izdaja_id}", category="danger")
        return render_template(
            "print.html", customer_data=cust, reverz_data=rev, datum_now=date.today()
        )
    else:
        flash(f"Reverz {izdaja_id} ne obstaja.", category="danger")

    return redirect(url_for("reverz_page"))


#
@app.route("/reverz/edit/<id>")
@login_required
def reverz_edit(id):
    """
    reverz_edit(id)
    route: /reverz/edit/<id>

    <id> številka reverza
    """
    rev_form = ReverzEditForm()
    (status, inventory) = reverz_list_single(id=id)
    if not status or not inventory:
        flash(f"Unable to load reverz {id}", category="danger")
        return redirect(url_for("reverz_page"))
    (status, inventory_single_list) = reverz_detail_single(id=id)
    if not status or not inventory_single_list:
        flash(f"Reverz {id} is empty", category="danger")

    rev_form.id.default = id
    rev_form.stranka.default = inventory["stranka"]
    rev_form.customer_id.default = inventory["customer_id"]
    rev_form.customer_id.choices = [inventory["customer_id"], inventory["stranka"]]

    rev_form.customer_person_id.default = inventory["customer_person_id"]
    (status, rev_form.customer_person_id.choices) = load_employee(
        inventory["customer_id"]
    )

    rev_form.person_id.default = inventory["person_id"]
    (status, rev_form.person_id.choices) = load_employee(1)

    rev_form.description.default = inventory["namen_testiranja"]
    rev_form.demo_start_date.default = inventory["datum_izdaje"]
    rev_form.demo_end_date.default = inventory["cas_testiranja_do"]
    rev_form.demo_result.default = inventory["rezultat_testiranja"]
    rev_form.demo_return_date.default = inventory["vrnjeno"]
    rev_form.active.default = inventory["aktiven"]
    rev_form.modified_by.default = (
        f"{inventory["last_user"]} ob {inventory["last_update"]}"
    )
    rev_form.process()
    return render_template(
        "edit.html",
        reverz_form=rev_form,
        inventory=inventory_single_list,
        datum_now=str(date.today()),
    )


@app.route("/reverz/edit/item/<rev_id>/<id>", methods=["GET", "POST"])
@login_required
def reverz_edit_item(rev_id=0, id=0):
    """
    reverz_edit_item(rev_id=0, id=0)

    <rev_id> številka reverza
    <id> številka transakcije

    Spreminjanje podatkov transakcije na reverzu za izbrano postavko
    """
    if request.method == "GET":
        rev_form = ReverzEditItemForm()
        (status, inventory) = reverz_detail_item_single(id=id)
        if not status or not inventory:
            flash(f"Unable to load item {id}", category="danger")
            return redirect(url_for("reverz_page"))
        (status, inventory_list) = reverz_detail_single(id=rev_id)
        if not status or not inventory_list:
            flash(f"Reverz {rev_id} is empty", category="danger")
            return redirect(url_for("reverz_page"))
        (status, stranka) = reverz_list_single(id=rev_id)
        if not status or not stranka:
            flash(f"Reverz {rev_id} ne obstaja", category="danger")
            return redirect(url_for("reverz_page"))

        rev_form.part_no.default = inventory["koda"]
        rev_form.description.default = inventory["opis"]
        rev_form.serial_no.default = inventory["serijska"]
        rev_form.demo_start_date.default = inventory["začetek"]
        rev_form.demo_end_date.default = inventory["konec"]
        rev_form.demo_return_date.default = inventory["vrnitev"]
        rev_form.namen.default = inventory["namen"]
        rev_form.notes.default = inventory["notes"]

        rev_form.process()
        return render_template(
            "edit_item.html",
            reverz_form=rev_form,
            inventory=inventory_list,
            stranka=stranka["stranka"],
            rev_id=rev_id,
            id=id,
            active=inventory["aktivna"],
            datum_now=str(date.today()),
        )

    if request.method == "POST":
        (status, e) = reverz_update_item_db(id=id, request_form=request.form)
        if status:
            flash(f"Item {id} sucessfully updated. Status: {e}", category="success")
        else:
            flash(f"Can't update item {id}. Error: {e}", category="danger")

    return redirect(url_for("reverz_edit", id=rev_id))


#
#
@app.route("/reverz/remove/item/<rev_id>/<id>", methods=["GET", "POST"])
@login_required
def reverz_remove(rev_id, id):
    """
    reverz_remove(rev_id, id)
    route: /reverz/remove/item/<rev_id>/<id>

    <rev_id> številka reverza
    <id> številka transakcije

    Deaktivira transakcijo na reverzu. Postavi status "active" na False.
    Iz inventarne številke se izbriše številka transakcije.
    """
    (status, e) = reverz_remove_item_db(id=id)
    if status:
        flash(
            f"Item {id} sucessfully removed from reverz. Status: {e}",
            category="success",
        )
    else:
        flash(f"Can't remove item {id}. Error: {e}", category="danger")
    return redirect(url_for("reverz_edit", id=rev_id))


#
@app.route("/reverz/update/<id>", methods=["GET", "POST"])
@login_required
def reverz_update(id):
    """
    reverz_update(id)
    route: /reverz/update/<id>

    <id> številka reverza

    Zapiše spremembe reverza v tabelo reverzi
    """
    if request.method == "POST":
        (status, e) = reverz_update_db(id=id, request_form=request.form)
        if status:
            flash(f"Reverz {id} sucessfully updated. Status: {e}", category="success")
        else:
            flash(f"Can't update reverz {id}. Error: {e}", category="danger")
    return redirect(url_for("reverz_page"))


#
# Reverz Closed
#
@app.route("/reverz/close/<id>", methods=["GET", "POST"])
@login_required
def reverz_close(id):
    """
    reverz_close(id)
    route:  /reverz/close/<id>

    <id> številka reverza

    Zaključi reverz. Če datum vrnitve ni podan, vpiše tekoči datum.
    Vse postavke v reverzu postavi status na False in vpiše temoči datum
    v datum vrnitve, če je ta prazen.
    """
    close_form = ReverzCloseForm()
    if request.method == "GET":
        close_form.reverz_id.data = id
        (status, cust) = reverz_list_single(id=id)
        (status, rev) = reverz_detail_single(id=id)
        return render_template(
            "view.html",
            customer_data=cust,
            reverz_data=rev,
            datum_now=date.today(),
            close_form=close_form,
        )
    if request.method == "POST":
        (status, cls) = reverz_close_db(id, form=close_form)
        flash(f"Reverz {id} closed. Status: {cls}", category="danger")

    return redirect(url_for("reverz_page"))


#
# Customer CRUD maintenance
#
@app.route("/customer", methods=["GET", "POST"])
@login_required
def customer_page():
    """
     Page for customer management.


     @return If successful return the template to render the customer.html
             If customer list is empty, redirect to customer_page and flash the error.

    customer_page()

    request.method:
    GET: Vnos nove stranke.
    POST: Zapis nove stranke v tabelo customer

    Stran customer.html
    """
    cust_form = CustomerForm()
    if request.method == "GET":
        (status, cust) = customer_list()
        if not status:
            flash("Unable to load customer list", category="danger")
            return redirect(url_for("customer_page"))

        return render_template("customer.html", customers=cust, cust_form=cust_form)

    if request.method == "POST":
        name = cust_form.name.data
        addr = cust_form.address.data
        active = cust_form.active.data
        (status, e) = customer_insert(name=name, addr=addr, active=active)
        if status:
            flash(
                f"Customer {name} addedd sucessfully. Status: {e}", category="success"
            )
        else:
            flash(
                f"Error adding customer. Rolling back changes. Error: {e}",
                category="danger",
            )
        return redirect(url_for("customer_page"))


#
@app.route("/customer/edit/<id>")
@login_required
def customer_edit(id):
    """
     Edit a customer. This will be a form for editing a customer

     @param id - The id of the customer to edit

     @return The template that renders the customer.html


    customer_edit(id)
    route: /customer/edit/<id>

    <id> koda stranke

    Vnos sprememb podatkov o stranki v tabeli customer
    Stran: customer.html
    """
    cust_form = CustomerForm()
    (status, cust) = customer_single(id=id)
    if not status:
        flash(f"Unable to load active inventory.", category="danger")
        return redirect(url_for("customer_page"))

    cust_form.name.default = cust["Name"]
    cust_form.address.default = cust["Address"]
    cust_form.active.default = cust["Active"]
    (status, customers) = customer_list()
    cust_form.process()

    return render_template(
        "customer.html", cust=cust, cust_form=cust_form, customers=customers
    )


@app.route("/customer/update/<id>", methods=["GET", "POST"])
@login_required
def customer_update(id):
    """
     Update a customer in the database

     @param id - id of the customer to update

     @return redirect to customer page

    customer_update(id)
    route: /customer/update/<id>

    <id> koda stranke

    Zapis sprememb o stranki v tabelo customer
    """
    cust_form = CustomerForm()
    if request.method == "POST":
        name = cust_form.name.data
        addr = cust_form.address.data
        active = cust_form.active.data
        (status, e) = customer_update_db(id=id, name=name, addr=addr, active=active)
        if status:
            flash(
                f"Customer {id} modified sucessfully. Status: {e}", category="success"
            )
        else:
            flash(
                f"Error updating customer {id}. Rolling back changes. Error: {e}",
                category="danger",
            )
    return redirect(url_for("customer_page"))


#
#
@app.route("/customer/delete/<id>", methods=["GET", "POST"])
@login_required
def customer_delete(id):
    """
     Delete a customer and all its data

     @param id - id of the customer to delete

     @return redirect to customer page

    customer_delete(id)
    route: /customer/delete/<id>

    <id> koda stranke

    Brisanje stranke iz tabele customer
    """
    (status, e) = customer_delete_db(id=id)
    if status:
        flash(f"Customer {id} sucessfully deleted. Status: {e}", category="success")
    else:
        flash(f"Can't delete customer {id}. Error: {e}", category="danger")
    return redirect(url_for("customer_page"))


#
# Category CRUD maintenance
#
@app.route("/category", methods=["GET", "POST"])
@login_required
def category_page():
    """
    category_page()

    request.method:
    GET: Vnos nove kategorije.
    POST: Zapis nove stranke v tabelo customer

    Stran customer.html
    """
    cat_form = CategoryForm()
    if request.method == "GET":
        (status, categories) = category_list()
        return render_template(
            "category.html", categories=categories, cat_form=cat_form
        )

    if request.method == "POST":
        id = cat_form.id.data
        desc = cat_form.description.data
        (status, e) = category_insert(id=id, desc=desc)
        if status:
            flash(f"Category {id} addedd sucessfully", category="success")
        else:
            flash(
                f"Error adding category {id}. Rolling back changes. {e}",
                category="danger",
            )
        return redirect(url_for("category_page"))


@app.route("/category/edit/<id>")
@login_required
def category_edit(id):
    """
    category_edit(id)
    route: /category/edit/<id>

    <id> kategorija ključ

    Vnos sprememb kategorije.
    Stran category.html
    """
    cat_form = CategoryForm()
    (status, cat) = category_single(id=id)
    if not status:
        flash(f"Unable to load category {id}", category="danger")
        return redirect(url_for("category_page"))

    cat_form.id.default = cat["id"]
    cat_form.description.default = cat["description"]
    (status, categories) = category_list()
    if not status:
        flash("Unable to load category list", category="danger")
        return redirect(url_for("category_page"))
    cat_form.process()

    return render_template(
        "category.html", cat=cat, cat_form=cat_form, categories=categories
    )


#
@app.route("/category/update/<id>", methods=["GET", "POST"])
@login_required
def category_update(id):
    """
    category_update(id)
    route: /category/update/<id>

    request.method:
    POST: Zapis sprememb v tabelo category

    Stran category.html
    """
    cat_form = CategoryForm()
    if request.method == "POST":
        id = cat_form.id.data
        desc = cat_form.description.data
        (status, e) = category_update_db(id=id, desc=desc)
        if status:
            flash(f"Category {id} modified sucessfully", category="success")
        else:
            flash(
                f"Error updating category {id}. Rolling back changes. {e}",
                category="danger",
            )
    return redirect(url_for("category_page"))


#
@app.route("/category/delete/<id>", methods=["GET", "POST"])
@login_required
def category_delete(id):
    """
    category_delete(id)
    route: /category/delete/<id>

    <id> kategorija ključ

    Brisanje kategorije iz tabele category.
    Stran customer.html
    """
    (status, e) = category_delete_db(id=id)
    if status:
        flash(f"Category {id} sucessfully deleted.", category="success")
    else:
        flash(f"Can't delete category {id} {e}", category="danger")
    return redirect(url_for("category_page"))


#
# Person CRUD maintenance
#
@app.route("/person", methods=["GET", "POST"])
@login_required
def person_page():
    """
    Page for persons. This is the first page where you can add / edit people.


    @return The persons page with form
    """
    per_form = PersonForm()
    if request.method == "GET":
        (status, persons) = person_list()
        return render_template("person.html", persons=persons, per_form=per_form)

    if request.method == "POST":
        name = per_form.name.data
        email = per_form.email.data
        phone = per_form.phone.data

        if per_form.validate_on_submit():
            (status, e) = person_insert(name=name, email=email, phone=phone)
            if status:
                flash(f"Person {name} addedd sucessfully", category="success")
            else:
                flash(
                    f"Error adding person {name}. Rolling back changes. {e}",
                    category="danger",
                )
        else:
            (status, persons) = person_list()
            return render_template("person.html", persons=persons, per_form=per_form)

        return redirect(url_for("person_page"))


@app.route("/person/edit/<id>")
@login_required
def person_edit(id):
    """
    Edit a person's details

    @param id - ID of the person to edit

    @return A page with person details
    """
    per_form = PersonForm()
    (status, per) = person_single(id=id)
    if not status:
        flash(f"Person {id} is missing", category="danger")
        return redirect(url_for("person_page"))
    per_form.name.default = per["Name"]
    per_form.email.default = per["Email"]
    per_form.phone.default = per["Phone"]
    (status, persons) = person_list()
    per_form.process()

    return render_template("person.html", per=per, per_form=per_form, persons=persons)


@app.route("/person/update/<id>", methods=["GET", "POST"])
@login_required
def person_update(id):
    """
    Update or create a person

    @param id - ID of the person to update

    @return The person page with the
    """
    per_form = PersonForm()
    if request.method == "POST":
        name = per_form.name.data
        email = per_form.email.data
        phone = per_form.phone.data

        if per_form.validate_on_submit():
            (status, e) = person_update_db(id=id, name=name, email=email, phone=phone)
            if status:
                flash(
                    f"Person {id} modified sucessfully. Status: {e}", category="success"
                )
            else:
                flash(
                    f"Error updating person {name}. Rolling back changes. Error: {e}",
                    category="danger",
                )
        else:
            (status, per) = person_single(id=id)
            (status, persons) = person_list()
            return render_template(
                "person.html", per=per, per_form=per_form, persons=persons
            )
    return redirect(url_for("person_page"))


@app.route("/person/delete/<id>", methods=["GET", "POST"])
@login_required
def person_delete(id):
    """
    Delete a person from the database

    @param id - ID of the person to delete

    @return Redirect to person page after
    """
    (status, e) = person_delete_db(id=id)
    if status:
        flash(f"Person {id} sucessfully deleted.", category="success")
    else:
        flash(f"Can't delete person {id} {e}", category="danger")
    return redirect(url_for("person_page"))


#
# Demo pool list CRUD maintenance
#
@app.route("/demopool", methods=["GET", "POST"])
@login_required
def demopool_page():
    """
    Page for demopool management.


    @return The template that renders the demopool
    """
    demopool_form = DemopoolForm()
    if request.method == "GET":
        (status, demopools) = demopool_list()
        return render_template(
            "demopool.html", demopools=demopools, demopool_form=demopool_form
        )

    if request.method == "POST":
        id = demopool_form.id.data
        description = demopool_form.description.data
        for_sale = demopool_form.for_sale.data
        (status, e) = demopool_insert(id=id, description=description, for_sale=for_sale)
        if status:
            flash(f"Demo pool {id} addedd sucessfully", category="success")
        else:
            flash(
                f"Error adding demo pool {id}. Rolling back changes. {e}",
                category="danger",
            )
        return redirect(url_for("demopool_page"))


@app.route("/demopool/edit/<id>")
@login_required
def demopool_edit(id):
    """
    Edit demopool with given id

    @param id - id of demopool to edit

    @return template to display demopool
    """
    demopool_form = DemopoolForm()
    (status, demo) = demopool_single(id=id)
    demopool_form.id.default = demo["id"]
    demopool_form.description.default = demo["description"]
    demopool_form.for_sale.default = demo["for_sale"]
    (status, demopools) = demopool_list()
    demopool_form.process()
    return render_template(
        "demopool.html", demo=demo, demopool_form=demopool_form, demopools=demopools
    )


@app.route("/demopool/update/<id>", methods=["GET", "POST"])
@login_required
def demopool_update(id):
    """
    Update Demo Pool. Should be a POST.

    @param id - Demo Pool ID to update.

    @return Redirects to Demo Pool page
    """
    demopool_form = DemopoolForm()
    if request.method == "POST":
        description = demopool_form.description.data
        for_sale = demopool_form.for_sale.data
        (status, e) = demopool_update_db(
            id=id, description=description, for_sale=for_sale
        )
        if status:
            flash(f"Demo pool {id} modified sucessfully", category="success")
        else:
            flash(
                f"Error updating demo pool {id}. Rolling back changes. {e}",
                category="danger",
            )
    return redirect(url_for("demopool_page"))


@app.route("/demopool/delete/<id>", methods=["GET", "POST"])
@login_required
def demopool_delete(id):
    """
    Delete Demo Pool and redirect to Demo Pool page.

    @param id - Demo Pool ID to delete.

    @return Redirection to Demo Pool page
    """
    (status, e) = demopool_delete_db(id)
    if status:
        flash(f"Demo pool {id} sucessfully deleted.", category="success")
    else:
        flash(f"Can't delete demo pool {id} {e}", category="danger")
    return redirect(url_for("demopool_page"))


#
# Employee CRUD maintenance
#
@app.route("/employee", methods=["GET", "POST"])
@login_required
def employee_page():
    """
    Renders employee page. This page is used to create or update an employee.


    @return The rendered employee page
    """
    employee_form = EmployeeForm()
    (status, employee_form.person_id.choices) = load_person()
    (status, employee_form.customer_id.choices) = load_customer()
    if request.method == "GET":
        (status, employees) = employee_list()

        return render_template(
            "employee.html", employees=employees, employee_form=employee_form
        )

    if request.method == "POST":
        if employee_form.validate_on_submit():
            person_id = employee_form.person_id.data
            customer_id = employee_form.customer_id.data
            title = employee_form.title.data
            status = employee_form.status.data
            email = employee_form.email.data
            (stat, e) = employee_insert(
                person_id=person_id,
                customer_id=customer_id,
                title=title,
                status=status,
                email=email,
            )
            if stat:
                flash(
                    f"Employee {person_id} addedd to {customer_id} sucessfully. Status: {e}",
                    category="success",
                )
            else:
                flash(
                    f"Error adding employee {person_id}. Rolling back changes. Error: {e}",
                    category="danger",
                )
        else:
            (status, employees) = employee_list()
            return render_template(
                "employee.html", employees=employees, employee_form=employee_form
            )

        return redirect(url_for("employee_page"))


@app.route("/employee/edit/<person_id>/<customer_id>")
@login_required
def employee_edit(person_id, customer_id):
    """
    Edit an employee. This is a view to edit an existing Employee

    @param person_id - ID of the Person who owns the Employee
    @param customer_id - ID of the Customer to whom the Employee belongs

    @return HTML form for editing an
    """
    employee_form = EmployeeForm()
    (status, emp) = employee_list_single(person_id=person_id, customer_id=customer_id)
    employee_form.person_id.default = emp["personid"]
    employee_form.person_id.choices = [(emp["personid"], emp["name"])]
    employee_form.customer_id.default = emp["customerid"]
    employee_form.customer_id.choices = [(emp["customerid"], emp["customer"])]
    employee_form.title.default = emp["title"]
    employee_form.status.default = emp["status"]
    employee_form.email.default = emp["companyemail"]
    (status, employees) = employee_list()
    employee_form.process()
    #
    return render_template(
        "employee.html", emp=emp, employee_form=employee_form, employees=employees
    )


@app.route("/employee/update/<person_id>/<customer_id>", methods=["GET", "POST"])
@login_required
def employee_update(person_id, customer_id):
    """
    Update employee. Method used for creating and editing Employee.

    @param person_id - Person to whom employee belongs.
    @param customer_id - Customer to whom employee belongs.

    @return If request method is POST returns list of employees with status " success "
    """
    employee_form = EmployeeForm()

    if request.method == "POST":
        (status, emp) = employee_list_single(
            person_id=person_id, customer_id=customer_id
        )
        employee_form.person_id.choices = [(emp["personid"], emp["name"])]
        employee_form.customer_id.choices = [(emp["customerid"], emp["customer"])]

        if employee_form.validate_on_submit():
            title = employee_form.title.data
            status = employee_form.status.data
            email = employee_form.email.data
            (stat, e) = employee_update_db(
                person_id=person_id,
                customer_id=customer_id,
                title=title,
                status=status,
                email=email,
            )
            if stat:
                flash(
                    f"Employee {person_id} modified sucessfully. Status: {e}",
                    category="success",
                )
            else:
                flash(
                    f"Error updating employee {person_id}. Rolling back changes. Error: {e}",
                    category="danger",
                )

        else:
            (status, emp) = employee_list_single(
                person_id=person_id, customer_id=customer_id
            )
            (status, employees) = employee_list()
            employee_form.person_id.default = emp["personid"]
            employee_form.person_id.choices = [(emp["personid"], emp["name"])]
            employee_form.customer_id.default = emp["customerid"]
            employee_form.customer_id.choices = [(emp["customerid"], emp["customer"])]
            employee_form.title.default = emp["title"]
            employee_form.status.default = emp["status"]
            employee_form.email.default = emp["companyemail"]

            return render_template(
                "employee.html",
                emp=emp,
                employees=employees,
                employee_form=employee_form,
            )

    return redirect(url_for("employee_page"))


@app.route("/employee/delete/<person_id>/<customer_id>", methods=["GET", "POST"])
@login_required
def employee_delete(person_id, customer_id):
    """
    Delete employee from database.

    @param person_id - ID of the person who wants to delete
    @param customer_id - ID of the employee's customer

    @return Redirect to page after deletion
    """
    (status, e) = employee_delete_db(person_id=person_id, customer_id=customer_id)
    if status:
        flash(
            f"Employee {person_id} sucessfully deleted from customer {customer_id}.",
            category="success",
        )
    else:
        flash(f"Can't delete employee {person_id} {e}", category="danger")
    return redirect(url_for("employee_page"))


#
# Inventory CRUD maintenance
#
@app.route("/inventory", methods=["GET", "POST"])
@login_required
def inventory_page():
    """
    Display or process inventory page.


    @return A view that renders the inventory
    """
    inventory_form = InventoryForm()
    (status, inventory_form.demo_pool.choices) = load_demopool()

    if request.method == "GET":
        (status, inventory) = inventory_list()
        (status, inventory_form.product_no.choices) = load_products()
        return render_template(
            "inventory.html", inventory=inventory, inventory_form=inventory_form
        )

    if request.method == "POST":
        product_no = inventory_form.product_no.data
        (stat, e) = inventory_insert(inventory_form=inventory_form)

        if stat:
            flash(
                f"Item {product_no} addedd to inventory sucessfully. Status: {e}",
                category="success",
            )
        else:
            flash(
                f"Error adding item  {product_no} to inventory. Rolling back changes. {e}",
                category="danger",
            )
        return redirect(url_for("inventory_page"))


@app.route("/inventory/edit/<id>/<product>")
@login_required
def inventory_edit(id, product):
    """
    Show form to edit inventory

    @param id - id of inventory to edit
    @param product - product for which inventory is shown

    @return html to display inventory for selected
    """
    inventory_form = InventoryForm()
    (status, inv) = inventory_list_single(id=id)
    inventory_form.id.default = id
    inventory_form.product_no.default = product
    inventory_form.product_no.choices = [
        [inv["produkt"], f'{inv["produkt"]} : {inv["opis"]}'],
    ]
    inventory_form.demo_pool.default = inv["demo_pool"]
    (status, inventory_form.demo_pool.choices) = load_demopool()
    inventory_form.serial_no.default = inv["serijska_st"]
    inventory_form.available.default = inv["razpolozljiva"]
    inventory_form.notes.default = inv["notes"]
    inventory_form.selectium_asset.default = inv["selectium_asset"]
    (status, inventory) = inventory_list()
    inventory_form.process()

    return render_template(
        "inventory.html",
        inv=inv,
        product_no=product,
        inventory_form=inventory_form,
        inventory=inventory,
    )


@app.route("/inventory/update/<id>/<product>", methods=["GET", "POST"])
@login_required
def inventory_update(id, product):
    """
    Update an item in the inventory

    @param id - id of the item to update
    @param product - product_no of the product to update

    @return redirect to the inventory page if
    """
    inventory_form = InventoryForm()
    if request.method == "POST":
        (stat, e) = inventory_update_db(
            id=id, product_no=product, inventory_form=inventory_form
        )
        if stat:
            flash(f"Item {id} modified sucessfully. Status: {e}", category="success")
        else:
            flash(
                f"Error updating item {id} in inventory. Rolling back changes. {e}",
                category="danger",
            )
    return redirect(url_for("inventory_page"))


@app.route("/inventory/delete/<id>", methods=["GET", "POST"])
@login_required
def inventory_delete(id):
    """
    Delete item from inventory.

    @param id - id of item to delete

    @return redirect to inventory page after
    """
    (status, e) = inventory_delete_db(id=id)
    if status:
        flash(
            f"Item {id} sucessfully deleted from inventory. Status: {e}",
            category="success",
        )
    else:
        flash(f"Can't delete item {id} from  inventory. Error: {e}", category="danger")
    return redirect(url_for("inventory_page"))


@app.route("/inventory/inventura", methods=["GET"])
@login_required
def inventory_inventura():
    (status, inv) = inventory_inventura_list()
    if status:
        return render_template("inventura.html", reverzi=inv, datum_now=date.today())
    else:
        flash("Can't list inventory items for Inventura")

    return render_template(url_for("home_page"))


@app.route("/inventory/export", methods=["GET"])
@login_required
def inventory_export():
    (status, inv) = inventory_export_csv()
    if status:
        return render_template("export_csv.html", reverzi=inv)
    else:
        flash("Can't list inventory items for Export")

    return render_template(url_for("home_page"))


#
# Products CRUD maintenance
#
@app.route("/product", methods=["GET", "POST"])
@login_required
def product_page():
    """
    Product page for admin.


    @return The product page to display
    """
    product_form = ProductForm()
    (status, product_form.category.choices) = load_categories()
    if request.method == "GET":
        (status, products) = product_list()
        return render_template(
            "product.html", products=products, product_form=product_form
        )

    if request.method == "POST":
        productno = product_form.productno.data
        description = product_form.description.data
        longdescription = product_form.longdescription.data
        category = product_form.category.data
        (status, e) = product_insert(
            productno=productno,
            description=description,
            longdescription=longdescription,
            category=category,
        )
        if status:
            flash(f"Product {productno} addedd sucessfully", category="success")
        else:
            flash(
                f"Error adding product {productno}. Rolling back changes. {e}",
                category="danger",
            )
        return redirect(url_for("product_page"))


@app.route("/product/edit/<id>")
@login_required
def product_edit(id):
    """
    Product edit page. Renders the product edit form and processes the product list.

    @param id - ID of the product to edit.

    @return Render the product edit form
    """
    product_form = ProductForm()
    (status, pro) = product_single(id)
    product_form.productno.default = pro["ProductNo"]
    product_form.description.default = pro["Description"]
    product_form.longdescription.default = pro["LongDescription"]
    product_form.category.default = pro["Category"]
    (status, product_form.category.choices) = load_categories()
    (status, products) = product_list()
    product_form.process()
    return render_template(
        "product.html", pro=pro, product_form=product_form, products=products
    )


@app.route("/product/update/<id>", methods=["GET", "POST"])
@login_required
def product_update(id):
    """
    Update a product in the database

    @param id - id of the product to update

    @return redirect to product page if
    """
    product_form = ProductForm()
    if request.method == "POST":
        description = product_form.description.data
        longdescription = product_form.longdescription.data
        category = product_form.category.data
        (status, e) = product_update_db(
            id=id,
            description=description,
            longdescription=longdescription,
            category=category,
        )
        if status:
            flash(f"Product {id} modified sucessfully. Status: {e}", category="success")
        else:
            flash(
                f"Error updating product {id}. Rolling back changes. {e}",
                category="danger",
            )

    return redirect(url_for("product_page"))


@app.route("/product/delete/<id>", methods=["GET", "POST"])
@login_required
def product_delete(id):
    """
    Delete product from database.

    @param id - Product id to delete.

    @return Redirect to product page after
    """
    (status, e) = product_delete_db(id=id)
    if status:
        flash(f"Product {id} sucessfully deleted. Status: {e}", category="success")
    else:
        flash(f"Can't delete product {id} {e}", category="danger")

    return redirect(url_for("product_page"))


#
# HELP
#
def help_make_key(id):
    """
    Make key for help.

    @param id - Help id to be used.

    @return Key for help with id
    """
    keys = id.split("#")
    help_key = ""
    for key in keys:
        help_key = help_key + key
    return help_key


def help_make_key_base(id):
    """
    Make key for help.

    @param id - Help id to be used.

    @return Key for help with id
    """
    keys = id.split("#")
    help_key = ""
    for key in keys:
        if not key.isnumeric():
            help_key = help_key + key
    return help_key


@app.route("/help/<id>", methods=["GET"])
def help_page(id=0):
    """
    Redirect to help page.

    @param id - id of page to redirect to.

    @return success or failure of help
    """
    url_back = id.replace("#", "/")
    (status, page) = help_page_db(help_make_key(id=id))
    if status and page:
        flash(page["help_entry"], category="info")

    else:
        flash("Za to stran še ni pomoči", category="danger")

    return redirect(url_back)


#
# Demo pool list CRUD maintenance
#
@app.route("/help/edit", methods=["GET", "POST"])
@login_required
def help_edit_page():
    """
    View to edit a page. If GET is requested the help page is displayed. If POST is requested the page is added to the database.


    @return Redirect to the edit page
    """
    help_form = HelpForm()
    if request.method == "GET":
        (status, help_pages) = help_page_list()
        return render_template(
            "help.html", help_pages=help_pages, help_form=help_form, new_page="True"
        )

    if request.method == "POST":
        id = help_form.page.data
        help_entry = help_form.help_entry.data
        (status, e) = help_insert_db(id=id, help_entry=help_entry)
        if status:
            flash(f"Help page {id} addedd sucessfully", category="success")
        else:
            flash(
                f"Error adding help page {id}. Rolling back changes. {e}",
                category="danger",
            )
        return redirect(url_for("help_edit_page"))


@app.route("/help/edit/<id>")
@app.route("/help/edit/<id>/<base_page>")
@login_required
def help_edit(id, base_page=0):
    """
    View to edit a help page

    @param id - id of the help page to edit

    @return html page with help page
    """
    help_form = HelpForm()
    (status, help_pages) = help_page_list()
    if base_page == "True":
        help_key = help_make_key_base(id=id)
    else:
        help_key = help_make_key(id=id)
    (status, demo) = help_single(id=help_key)
    if status and demo:
        help_form.page.default = demo["page"]
        help_form.help_entry.default = demo["help_entry"]
    else:
        help_form.page.default = help_key
        help_form.process()
        return render_template(
            "help.html", help_pages=help_pages, help_form=help_form, new_page="True"
        )

    help_form.process()
    return render_template(
        "help.html",
        demo=demo,
        help_form=help_form,
        help_pages=help_pages,
        new_page="False",
    )


@app.route("/help/update/<id>", methods=["GET", "POST"])
@login_required
def help_update(id):
    """
    Update a help page.

    @param id - The id of the help page to update.

    @return Redirect to the edit page
    """
    help_form = HelpForm()
    if request.method == "POST":
        help_entry = help_form.help_entry.data
        (status, e) = help_update_db(id=id, help_entry=help_entry)
        if status:
            flash(f"Help page {id} modified sucessfully", category="success")
        else:
            flash(
                f"Error updating help page {id}. Rolling back changes. {e}",
                category="danger",
            )
    return redirect(url_for("help_edit_page"))


@app.route("/help/delete/<id>", methods=["GET", "POST"])
@login_required
def help_delete(id):
    """
    Delete a help page.

    @param id - ID of the help page to delete.

    @return Redirect to the edit page
    """
    (status, e) = help_delete_db(id)
    if status:
        flash(f"Help page {id} sucessfully deleted.", category="success")
    else:
        flash(f"Can't delete help page {id} {e}", category="danger")
    return redirect(url_for("help_edit_page"))


#
#
# Database Backup
@app.route("/backup", methods=["GET"])
@login_required
def backup_page():
    """
     Backup reverzi database to backup_db / directory


     @return redirect to home page if

    backup_page()

    Backup reverzi database to backup_db/ directory.
    """
    url = request.url_rule.endpoint
    if request.method == "GET":
        flash("Database Backup In progress...", category="success")
        logger.info("DB Backup start")
        (status, result) = backup_db(
            host=DB_HOST,
            db=DB_NAME,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASS,
            local_file_path="/var/opt/reverz/backup/",
        )
        logger.info(f"DB Backup status: {status}, {result}")
        if status:
            flash(
                f"Database Backup Successfull. Status {status}",
                category="success",
            )
        else:
            flash(
                f"Database Backup Failed {result}. Status {status}", category="danger"
            )

    return redirect(url_for("home_page"))


@app.route("/logout")
def logout_page():
    """
    Logs the user out and redirects to the login page.


    @return A redirect to the login page
    """
    logout_user()
    return redirect(url_for("login_page"))


@app.route("/login", methods=["GET", "POST"])
def login_page():
    """
    Displays the login page.


    @return Redirect to home page if user is already logged
    """
    if current_user.is_authenticated:
        return redirect(url_for("home_page"))

    form = LoginForm()
    if request.method == "POST":
        if form.validate_on_submit():
            user = User.authenticate(
                username=form.username.data, password=form.password.data
            )
            if user:
                login_user(user)
                return redirect(request.args.get("next") or url_for("home_page"))

    return render_template("login.html", title="Login", form=form)


@app.route("/search/<id>", methods=["POST", "GET"])
@login_required
def inventory_search(id=0):
    """
     Search inventory by search expression

     @param id - inventory id to search ( default 0 )

     @return a template with search results

    inventory_search(id=0)

    Search full inventory by search expression in id
    """
    (status, reverzi) = inventory_search_db(request.form.get("id_search"))
    if status:
        return render_template(
            "search.html",
            reverzi=reverzi,
            datum_now=str(date.today()),
        )
    else:
        flash(f"Problem with search engine. Status: {reverzi}")
    return redirect(url_for("search_page"))


@app.route("/ajaxfile", methods=["GET", "POST"])
def ajaxfile():
    """
    Redirect to help page.

    @param id - id of page to redirect to.

    @return success or failure of help
    """
    id = request.form["id"]
    (status, page) = help_page_db(help_make_key(id=id))

    return jsonify(
        {"htmlresponse": render_template("response.html", page=page["help_entry"])}
    )


@app.route("/ajaxreverz", methods=["GET", "POST"])
def ajaxreverz():
    """
    Redirect to help page.

    @param id - id of page to redirect to.

    @return success or failure of help
    """
    id = request.form["id"]
    (status, page) = reverz_list_single(id=id)

    return jsonify({"htmlresponse": render_template("response1.html", page=page)})
