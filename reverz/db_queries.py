from reverz import conn, cursor, cursor_list
from datetime import date
from dateutil import parser
import psycopg2.extras
from flask_login import current_user


#
# Common functions
#
def check_date(date_string) -> bool:
    """
    Checks if date_string is valid. It returns True if it is False if it is not.

    @param date_string - string to be checked. It can be formatted by date. format ('yyyy - mm - dd')

    @return True if date_string is valid False if it is

    check_date(date_string)

    <date_string> string parameter z datumom

    Funkcija preveri, če je zapis v parametru veljaven datum.
    """
    try:
        return bool(parser.parse(date_string))
    except Exception:
        return False


def check_missing_date(date_field) -> str:
    """
    Check for missing date in date_field. If date_field is empty string, return None, else return date string.
    """
    if date_field == "":
        return None
    return date_field


def execute_sql(curs, sql, data=(None,)):
    """
    Execute SQL and return status and rezult. This is a generic procedure to be used in conjunction with

    @param curs - cursor object from db. cursor
    @param sql - SQL statement to be executed
    @param data - tuple of data to be inserted into sql statement

    @return tuple of ( status result ) status : True / False rezult : SQL

    Generic procedure to execute sql statement

    Return tupple (status, result)
    """
    try:
        curs.execute(sql, data)
        conn.commit()
        status = True
    except Exception as result:
        conn.rollback()
        status = False

    result = curs.statusmessage
    return status, result


def execute_select_all(curs, sql, data=(None,)):
    """
    Execute SQL statement and return all matching rows. This is a wrapper around .fetchall to handle postgresql cursor and sql statements

    @param curs - cursor to use for execution
    @param sql - SQL statement to be executed. It must be a string
    @param data - tuple of data to be inserted into sql

    @return True / False result : list of

    execute_select_all(curs, sql, data=(0,))

    Execute sql statement SQL in cursor curs and return all matching rows.

    "curs" - postgresql cursor
    "sql" - SQL statement to execute

    Return <True/False>, <sql result>
    """
    try:
        curs.execute(sql, data)
        result = curs.fetchall()
        conn.commit()
    except Exception as e:
        conn.rollback()
        return False, e

    return True, result


def execute_select_one(curs, sql, data=(None,)):
    """
    Execute SQL statement and return first matching row. This is a wrapper around execute_select_one that handles postgresql cursor and the exception handling

    @param curs - cursor used to execute SQL statement
    @param sql - SQL statement to be executed. It must be a single string
    @param data - tuple of data to be inserted into sql

    @return tuple of True / False and result

    execute_select_one(curs, sql, data=(None,))

    Execute sql statement SQL in cursor curs and return first matching row.

    "curs" - postgresql cursor
    "sql" - SQL statement to execute

    Return <True/False>, <sql result>
    """
    try:
        curs.execute(sql, data)
        result = curs.fetchone()
        conn.commit()
    except Exception as e:
        conn.rollback()
        return False, e

    return True, result


def load_categories():
    """
    Load category list from view category_list for dropdown select. This function is called by ajax request to load category list from view.


    @return list of ids and descriptions of loaded categories in format id :

    load_categories()

    Load category list from view category_list for dropdown select
    """
    return execute_select_all(
        curs=cursor_list,
        sql="SELECT id, id || ' : ' || description as description FROM category_list;",
    )


def load_customer():
    """
     Load customer's list from view customer_list for dropdown select. This function is used to load customer's list from view customer_

    Load customer's list from view customer_list for dropdown select
    """
    return execute_select_all(
        curs=cursor_list, sql='SELECT id, "Name" FROM customer_list;'
    )


def load_person(id=0):
    """
    Load person's list from view person_list for dropdown select. This function is called by : func : ` load_person `

    @param id - person id to load.

    @return list of person's id and name as strings
    """
    return execute_select_all(
        curs=cursor_list, sql='SELECT id, "Name" FROM person_list;'
    )


def load_employee(customer_id=0):
    """
    Load employee's list from view empolyee_list for select

    @param customer_id - Customer id to load employee for

    @return ( status result ) status : 0 / 1 result : list of employee

    load_employee(id=0)

    Load employee's list from view empolyee_list for dropdown select
    """
    # This function will return the id of the first person in the employee list.
    if customer_id == 0:
        (status, result) = execute_select_all(
            curs=cursor_list, sql="SELECT id, personid, name FROM employee_list;"
        )
    else:
        (status, result) = execute_select_all(
            curs=cursor_list,
            sql="SELECT personid, name FROM employee_list WHERE customerid = %(customer_id)s;",
            data={
                "customer_id": customer_id,
            },
        )

    return status, result


def load_demopool():
    """
    Load Demo Pool list from view and return list of demopool IDs and descriptions.


    @return list of demopool IDs and descriptions in format { id :

    load_demopool()

    Load demo pool list from view demopool_list for dropdown select
    """
    return execute_select_all(
        curs=cursor_list,
        sql="SELECT id, id || ' : ' || Description as description FROM demopool_list;",
    )


def load_products():
    """
    Load products list from view products_list for dropdown select. This function is used to load product information from view products_list for dropdown select.


    @return a list of dictionaries with product information. Each dictionary is keyed by partno

    load_products()

    Load products list from view products_list for dropdown select
    """
    return execute_select_all(
        curs=cursor_list,
        sql='SELECT "ProductNo" as partno, "ProductNo" || \' : \' || "Description" as description from products_list;',
    )


#
#
# Reverz ----------------------------------------------------------------------
def reverz_list(limit=0):
    """
     Return all reverzes from view. This is a generator that yields tuples ( row_id column_name ).


     @return a generator that yields tuples ( row_id column_name

    reverz_list()

    Return all reverzes from view reverz_list
    """
    sql_limit = (
        ""
        if not limit
        else " where cas_testiranja_do <= now() + interval '1 week' and aktiven"
    )
    return execute_select_all(
        curs=cursor, sql=f"SELECT * FROM reverz_list {sql_limit};"
    )


def reverz_insert(customer_id, request_form):
    """
     Inserts a reverz record into database. This is a wrapper for reverz_insert that will be called in transaction.

     @param customer_id - id of the customer to which record is to be inserted
     @param request_form - data from the form that is passed

     @return True if insert was

    reverz_insert(customer_id, request_form)

    Insert new reverz for customer into table reverzi.
    Add all selected items into transaction table.

    "customer_id" - customer id number
    "request_form" - data from input form
    """
    demo_start_date = check_missing_date(request_form["demo_start_date"])
    demo_end_date = check_missing_date(request_form["demo_end_date"])
    active = "y"
    rezult = ""
    try:
        sql = (
            "INSERT INTO reverzi  ("
            + "customer_id,"
            + "customer_person_id,"
            + "person_id,"
            + "description,"
            + "demo_start_date,"
            + "demo_end_date,"
            + "active,"
            + "last_user)"
            + " VALUES ("
            + "%(customer_id)s,"
            + "%(customer_person_id)s,"
            + "%(person_id)s,"
            + "%(description)s,"
            + "%(demo_start_date)s,"
            + "%(demo_end_date)s,"
            + "%(active)s,"
            + "%(last_user)s"
            + ") RETURNING id;"
        )
        data = {
            "customer_id": customer_id,
            "customer_person_id": request_form["customer_person_id"],
            "person_id": request_form["person_id"],
            "description": request_form["description"],
            "demo_start_date": demo_start_date,
            "demo_end_date": demo_end_date,
            "active": active,
            "last_user": current_user.username,
        }

        cursor.execute(sql, data)
        rezult = f"Reverz {cursor.statusmessage} "
        cust_id = cursor.fetchone()
        id = cust_id["id"]
    except Exception as e:
        rezult += f" Error reverz: {e}"
        conn.rollback()
        return False, e

    try:
        sql2 = "INSERT INTO transactions (inventory_id, reverz_id, active, demo_start_date, demo_end_date, last_user) VALUES "
        data2 = ()

        for key in request_form:
            if key.isnumeric():
                sql2 += "(%s,%s,%s,%s,%s,%s),"
                data2 += (
                    key,
                    id,
                    active,
                    demo_start_date,
                    demo_end_date,
                    current_user.username,
                )
        sql2 = sql2.rstrip(",") + ";"
        if len(data2):
            cursor.execute(sql2, data2)
            rezult += f"Item {cursor.statusmessage}"
        else:
            rezult += "-- No items selected from item list --"
        conn.commit()

    except Exception as e:
        conn.rollback()
        rezult += f" Error item: {e}"
        return False, e

    return True, rezult


def reverz_add_items(id, request_form):
    """
     Add items to reverz. This is a helper function to handle the request_form.

     @param id - ID of the item to add. It should be a string of the form " item_id "
     @param request_form - Dictionary containing the data required to

    reverz_add_item

    insert new item from inventory to reverz.
    """
    demo_start_date = check_missing_date(request_form["demo_start_date"])
    demo_end_date = check_missing_date(request_form["demo_end_date"])

    sql = "INSERT INTO transactions (inventory_id, reverz_id, active, demo_start_date, demo_end_date, last_user) VALUES "
    data = ()
    for key in request_form:
        if key.isnumeric():
            sql += "(%s,%s,%s,%s,%s,%s),"
            data += (
                key,
                id,
                "y",
                demo_start_date,
                demo_end_date,
                current_user.username,
            )
    sql = sql.rstrip(",") + ";"
    return execute_sql(curs=cursor, sql=sql, data=data)


def reverz_update_db(id, request_form):
    """
     Updates a reverz row in the database. This is a wrapper around reverz_update_row to ensure that the data is in the correct format before inserting it into the database.

     @param id - The id of the row to update. It is assumed that this is the primary key of the row.
     @param request_form - The form containing the data to update the row with.

     @return True if successful False otherwise. Raises an exception if there is a problem

    reverz_update_db(id, request_form)

    Update existing reverz ROW.
    """
    data = {
        "customer_person_id": request_form["customer_person_id"],
        "person_id": request_form["person_id"],
        "description": request_form["description"],
        "demo_start_date": check_missing_date(request_form["demo_start_date"]),
        "demo_end_date": check_missing_date(request_form["demo_end_date"]),
        "demo_return_date": check_missing_date(request_form["demo_return_date"]),
        "demo_result": request_form["demo_result"],
        "last_user": current_user.username,
        "id": id,
    }
    sql = (
        "UPDATE reverzi SET "
        + "customer_person_id=%(customer_person_id)s,"
        + "person_id=%(person_id)s,"
        + "description=%(description)s,"
        + "demo_start_date=%(demo_start_date)s,"
        + "demo_end_date=%(demo_end_date)s,"
        + "demo_return_date=%(demo_return_date)s,"
        + "demo_result=%(demo_result)s,"
        + "last_user=%(last_user)s"
        + " WHERE id=%(id)s;"
    )

    return execute_sql(curs=cursor, sql=sql, data=data)


def reverz_update_item_db(id, request_form):
    """
     Update an item in the database. This is a wrapper for reverz_update_item_db () and updates the selected item row in the transactions table

     @param id - The ID of the item to update
     @param request_form - The data submitted from the user that contains the request information

     @return True if successful False if not. False is returned in case of

    reverz_update_item_db(id, request_form)

    Update selected item ROW
    """
    data = {
        "id": id,
        "loan_reason": request_form["namen"],
        "demo_start_date": check_missing_date(request_form["demo_start_date"]),
        "demo_end_date": check_missing_date(request_form["demo_end_date"]),
        "demo_return_date": check_missing_date(request_form["demo_return_date"]),
        "notes": request_form["notes"],
        "last_user": current_user.username,
    }

    sql = (
        "UPDATE transactions SET "
        + "loan_reason=%(loan_reason)s,"
        + "demo_start_date=%(demo_start_date)s,"
        + "demo_end_date=%(demo_end_date)s,"
        + "demo_return_date=%(demo_return_date)s,"
        + "notes=%(notes)s,"
        + "last_user=%(last_user)s"
        + " WHERE id=%(id)s;"
    )

    return execute_sql(curs=cursor, sql=sql, data=data)


def reverz_close_db(id, form):
    """
     Close reverz and update database. This is a wrapper for reverz_close

     @param id - id of the reverz to close
     @param form - form with demostring_result and demo_result

     @return True if success False if not ( error message will be printed

    reverz_close(id)

    Close the reverz id. Set status on all transactions for reverz to False.
    """
    return execute_sql(
        curs=cursor,
        sql="UPDATE reverzi SET active='n', demo_result=%s, last_user=%s WHERE id=%s;",
        data=(form.demo_result.data, current_user.username, id),
    )


def reverz_list_single(id):
    """
     Return data for single reverz. This is a wrapper for reverz_list_single

     @param id - ID of record to return

     @return dict of data for single reverz or None if not

    reverz_single_list(id)

    Return data for single reverz id.
    """
    return execute_select_one(
        curs=cursor,
        sql="SELECT * FROM reverz_list WHERE reverz = %s LIMIT 1;",
        data=(id,),
    )


def reverz_detail_single(id):
    """
     Get detailed data for single reverz. This is a wrapper for reverz_detail

     @param id - ID of the reverz to get detailed data for

     @return dict with all items for single reverz as

    reverz_detail_single(id)

    Return detailed data with all items for single reverz id from view reverz_detail.
    """
    return execute_select_all(
        curs=cursor,
        sql="SELECT * FROM reverz_detail WHERE reverz_detail.reverz = %s;",
        data=(id,),
    )


def reverz_detail_item_single(id):
    """
     Get detailed data for a single item. This is a wrapper for reverz_detail_item_from_view ()

     @param id - ID of the item to retrieve.

     @return dict or None if not found. Note that the keys are : trans_id

    reverz_detail_item_single(id)

    Return detailed data for item id from view reverz_detail.
    """
    return execute_select_one(
        curs=cursor,
        sql="SELECT * FROM reverz_detail WHERE reverz_detail.trans_id = %s;",
        data=(id,),
    )


def reverz_detail_single_archive(id):
    """
     Get detailed data for single reverz. This is a wrapper for reverz_detail_archive

     @param id - ID of the reverz to get detailed data for

     @return dict with all items for single reverz as

    reverz_detail_single(id)

    Return detailed data with all active and archive items for single reverz id from view reverz_detail_archive.
    """
    return execute_select_all(
        curs=cursor,
        sql="SELECT * FROM reverz_detail_archive WHERE reverz_detail_archive.reverz = %s;",
        data=(id,),
    )


def reverz_remove_item_db(id):
    """
     Remove item from reverz number database. This is a wrapper for reverz_remove_item_db with the ability to set the last_user to the user who added the item

     @param id - id of the item to remove

     @return True if success False if not ( error is logged

    reverz_remove_item_db(id)

    (id) reverz number

    Set status of the item to false. Item is now not shown on the reverz and is free to add into another reverz.
    """
    return execute_sql(
        curs=cursor,
        sql="UPDATE transactions SET active='n', last_user=%s WHERE id = %s;",
        data=(current_user.username, id),
    )


#
# Inventory --------------------------------------------------------------------
def inventory_active():
    """
    Get a list of all active inventory items.


    @return a list of active inventory
    """
    return execute_select_all(curs=cursor, sql="SELECT * FROM inventory_active;")


def inventory_list():
    """
    List all inventory_ids in the database.


    @return a list of tuples ( id_str name
    """
    return execute_select_all(curs=cursor, sql="SELECT * FROM inventory_list;")


def inventory_long_list():
    """
    List all long inventory ids.


    @return a list of inventory ids
    """
    return execute_select_all(curs=cursor, sql="SELECT * FROM inventory_long_list;")


def inventory_list_single(id):
    """
    Get inventory_list for a single inventarna

    @param id - id of the inventarna to get

    @return dict or None if not
    """
    return execute_select_one(
        curs=cursor,
        sql="SELECT * FROM inventory_list WHERE inventarna_st=%s LIMIT 1;",
        data=(id,),
    )


def inventory_export_csv(filter="demo_pool like 'Selectium Demo Pool'"):
    """
    Create  export list for device registration in HPE Networking Support

    Columns returned

    device name, serial number, description

    Param filter - sql filter expresion. Default is "demo_pool like '%Selectium%Demo Pool%'"

    @return dict or None if no lines are selected
    """
    sql = f"SELECT produkt, serijska_st, opis FROM inventory_list WHERE serijska_st IS NOT NULL and {filter};"
    print(sql)
    print(execute_sql(curs=cursor, sql=sql, data=(None, None)))
    return execute_select_all(curs=cursor, sql=sql, data=(None, None))


def inventory_inventura_list():
    """
    List of all inventories of the database


    @return Return a list with the values of the table inventory_long_
    """
    return execute_select_all(
        curs=cursor,
        sql=(
            "SELECT DISTINCT ON (inventarna_st, selectium_asset, produkt, serijska_st) *, "
            + "reverz_active, "
            + "reverz_id, "
            + "trans_id, "
            + "opis, "
            + "demo_pool, "
            + "namen, "
            + "notes, "
            + "customer_person_name, "
            + "person_name, "
            + "demo_start_date, "
            + "demo_end_date, "
            + "demo_return_date, "
            + "item_start_date, "
            + "item_end_date, "
            + "item_return_date, "
            + "last_update, "
            + "last_user "
            + "FROM inventory_long_list "
            + "WHERE selectium_asset IS NOT NULL "
            + "ORDER BY selectium_asset; "
        ),
    )


# def inventory_insert(product_no, serial_no, available, demo_pool, notes ):
def inventory_insert(inventory_form) -> tuple[bool, any]:
    """inventory_form(inventory_form):

    Zapiše nov inventar v tabelo inventory

    """
    data = {
        "ProductNo": inventory_form.product_no.data,
        "SerialNo": inventory_form.serial_no.data,
        "Available": inventory_form.available.data,
        "DemoPool": inventory_form.demo_pool.data,
        "notes": inventory_form.notes.data,
        "selectium_asset": inventory_form.selectium_asset.data,
        "last_user": current_user.username,
    }

    if inventory_form.selectium_asset.data:
        data["selectium_asset"] = inventory_form.selectium_asset.data

    sql = (
        "INSERT INTO inventory  ("
        + '"ProductNo",'
        + '"SerialNo",'
        + '"Available",'
        + '"DemoPool",'
        + "notes,"
    )
    if inventory_form.selectium_asset.data:
        sql += "selectium_asset,"
    sql += "last_user) VALUES (%(ProductNo)s,%(SerialNo)s,%(Available)s,%(DemoPool)s,%(notes)s,"

    if inventory_form.selectium_asset.data:
        sql += "%(selectium_asset)s,"
    sql += "%(last_user)s)"

    return execute_sql(curs=cursor, sql=sql, data=data)


def inventory_update_db(id, product_no, inventory_form):
    """
     Update an inventory in the database

     @param id - ID of the inventory to update
     @param product_no - ProductNo of the item to update
     @param inventory_form - InventoryForm object with the data we want to update

     @return True if successful False if


    Update inventory item
    """
    data = {
        "ProductNo": product_no,
        "SerialNo": inventory_form.serial_no.data,
        "Available": inventory_form.available.data,
        "DemoPool": inventory_form.demo_pool.data,
        "notes": inventory_form.notes.data,
        "selectium_asset": inventory_form.selectium_asset.data,
        "last_user": current_user.username,
        "id": id,
    }
    sql = (
        "UPDATE inventory SET "
        + '"ProductNo"=%(ProductNo)s,'
        + '"SerialNo"=%(SerialNo)s,'
        + '"Available"=%(Available)s,'
        + '"DemoPool"=%(DemoPool)s,'
        + "notes=%(notes)s,"
        + "selectium_asset=%(selectium_asset)s,"
        + "last_user=%(last_user)s"
        + " WHERE id = %(id)s;"
    )
    return execute_sql(curs=cursor, sql=sql, data=data)


def inventory_delete_db(id):
    """
    Delete an item from the inventory database

    @param id - ID of the item to delete

    @return True if successful False if

    inventory_delete_db(id)

    Delete item (id) from inventory.
    Item can be deleted, if no transactions was registered for this item.
    """
    return execute_sql(
        curs=cursor, sql="DELETE FROM inventory WHERE  id = %s;", data=(id,)
    )


#
#
# Customer ---------------------------------------------------------------------
def customer_list():
    """
     Return data for view customer_list


     @return Return data for view customer_

    customer_list()

    Return  data for from view customer_list.
    """
    return execute_select_all(curs=cursor, sql=("SELECT * FROM customer_list;"))


def customer_insert(name, addr, active):
    """
     Insert a new customer into the database

     @param name - The name of the customer
     @param addr - The address of the customer
     @param active - True if the customer is active

     @return The id of the newly created

    customer_insert(name, addr, active)

    Insert new customer row.
    """
    return execute_sql(
        curs=cursor,
        sql='INSERT INTO customer ("Name", "Address", "Active", last_user) VALUES (%s, %s, %s, %s);',
        data=(name, addr, active, current_user.username),
    )


def customer_single(id):
    """
     Retrieve data for a single customer

     @param id - id of the customer to retrieve

     @return dictionary with customer's

    customer_single(id)

    Return data for single customer id from table customer.
    """
    return execute_select_one(
        curs=cursor, sql="SELECT * FROM customer WHERE id = %s LIMIT 1;", data=(id,)
    )


def customer_update_db(name, addr, active, id):
    """
     Update a customer in the database

     @param name - The name of the customer
     @param addr - The address of the customer
     @param active - True if the customer is active
     @param id - The id of the customer

     @return True if successful False if

    customer_update_db(name, addr, active, id)

    Update customer row.
    """
    return execute_sql(
        curs=cursor,
        sql='UPDATE customer SET "Name"=%s, "Address"=%s, "Active"=%s, last_user=%s WHERE id = %s;',
        data=(name, addr, active, current_user.username, id),
    )


def customer_delete_db(id):
    """
     Delete a customer from the database

     @param id - ID of the customer to delete

     @return True if successful False if

    customer_delete_db(id)

    Delete customer row from table customer
    """
    return execute_sql(
        curs=cursor, sql="DELETE FROM customer WHERE  id = %s;", data=(id,)
    )


#
# Category -----------------------------------------------------------------------
def category_list():
    """
     Return data for view category_list.


     @return list of dictionaries with key " category

    category_list()

    Return data for from view category_list.
    """
    return execute_select_all(curs=cursor, sql="SELECT * FROM category_list;")


def category_insert(id, desc):
    """
     Insert a new category into the database

     @param id - id of the category to be created
     @param desc - description of the category to be created

     @return True if success False if

    category_insert(id, desc)

    Insert new category into table category
    """
    return execute_sql(
        curs=cursor,
        sql="INSERT INTO  category (id, description, last_user) VALUES  (%s, %s, %s);",
        data=(id, desc, current_user.username),
    )


def category_single(id):
    """
     Return data for single category

     @param id - ID of category to return

     @return dictionary with data or None if not

    category_single(id)

    Return data for single category from table category.
    """
    return execute_select_one(
        curs=cursor, sql="SELECT * FROM category WHERE id = %s LIMIT 1;", data=(id,)
    )


def category_update_db(id, desc):
    """
     Update category in database.

     @param id - ID of category to update
     @param desc - New description of category

     @return True if success False

    category_update_db(id, desc)

    Update category row in table category
    """
    print(f"Update category user {current_user.username}")
    return execute_sql(
        curs=cursor,
        sql="UPDATE category SET description=%s, last_user=%s WHERE id = %s;",
        data=(desc, current_user.username, id),
    )


def category_delete_db(id):
    """
     Delete category from database.

     @param id - ID of category to delete.

     @return True if successful False otherwise

    category_delete_db(id)

    Delete category row from table category.
    Delete will fail if category is used by products.
    """
    return execute_sql(
        curs=cursor, sql="DELETE FROM category WHERE id = %s;", data=(id,)
    )


#
# Person ----------------------------------------------------
def person_list():
    """
     Return data for view person_list.


     @return list of dictionaries with keys " name " and " email

    person_list()

    Return data for from view person_list.
    """
    return execute_select_all(curs=cursor, sql="SELECT * FROM person_list;")


def person_insert(name, email, phone):
    """
     Insert a new person into the person table

     @param name - Name of the person to be created
     @param email - Email of the person to be created
     @param phone - Phone number of the person to be created

     @return True if successful False if

    person_insert(name, email, phone)

    Insert new person row into table person
    """
    return execute_sql(
        curs=cursor,
        sql='INSERT INTO  person ( "Name", "Email", "Phone", last_user) VALUES (%s, %s, %s, %s);',
        data=(name, email, phone, current_user.username),
    )


def person_single(id):
    """
     Return data for single person

     @param id - id of person to return

     @return dictionary with data for single

    person_single(id)

    Return data for single person from table person.
    """
    return execute_select_one(
        curs=cursor, sql="SELECT * FROM person WHERE id = %s LIMIT 1;", data=(id,)
    )


def person_update_db(id, name, email, phone):
    """
     Update person in database.

     @param id - ID of person to update
     @param name - Name of person to update
     @param email - Email of person to update
     @param phone - Phone of person to update

     @return True if successful False if

    person_update_db(id, name, email, phone)

    Update person's row in table person.
    """
    return execute_sql(
        curs=cursor,
        sql='UPDATE person SET "Name"=%s, "Email"=%s, "Phone"=%s, last_user=%s WHERE id = %s;',
        data=(name, email, phone, current_user.username, id),
    )


def person_delete_db(id):
    """
     Delete person from reverz database

     @param id - id of person to delete

     @return True if success False if

    person_delete_db(id)

    Delete peron (id) from table person.
    Delete will fail if person is related to customer in employee table or it is used in reverz.
    """
    return execute_sql(curs=cursor, sql="DELETE FROM person WHERE id = %s", data=(id,))


#
# Demopool --------------------------------------------------
def demopool_list():
    """
     Return data for view demopool_list


     @return list of dictionaries with data

    demopool_list()

    Return data for from view demopool_list.
    """
    return execute_select_all(curs=cursor, sql=("SELECT * FROM demopool_list;"))


def demopool_insert(id, description, for_sale):
    """
     Insert a demopool row into the database

     @param id - ID of the row to insert
     @param description - Description of the row to insert
     @param for_sale - True if the row is for sale

     @return True if the insert was

    demopool_insert(id, description, for_sale)

    Insert new demopool row in table demopool
    """
    return execute_sql(
        curs=cursor,
        sql="INSERT INTO demopool (id, description, for_sale, last_user) VALUES (%s, %s, %s, %s);",
        data=(id, description, for_sale, current_user.username),
    )


def demopool_single(id):
    """
     Get data for single demopool

     @param id - id of demopool to get

     @return dict of data for single

    demopool_single(id)

    Return data for single demopool from table demopool.
    """
    return execute_select_one(
        curs=cursor, sql="SELECT * FROM demopool WHERE id = %s LIMIT 1;", data=(id,)
    )


def demopool_update_db(id, description, for_sale):
    """
     Update a demopool row in the database

     @param id - ID of the row to update
     @param description - Description of the row to update
     @param for_sale - True if the row is for sale

     @return True if successful False

    demopool_update_db(id, description, for_sale)

    Update demopool row in table demopool
    """
    return execute_sql(
        curs=cursor,
        sql="UPDATE demopool SET description=%s, for_sale=%s, last_user=%s WHERE id = %s;",
        data=(description, for_sale, current_user.username, id),
    )


def demopool_delete_db(id):
    """
     Delete a demopool row from the database

     @param id - ID of the row to delete

     @return True if successful False if

    demopool_delete_db(id)

    Delete demopool row from table demopool
    """
    return execute_sql(
        curs=cursor, sql="DELETE FROM demopool WHERE id = %s;", data=(id,)
    )


#
# Employee ---------------------------------------------------
def employee_list():
    """
     Return data for from view employee_list


     @return a list of dictionaries each containing : id ( str

    employee_list()

    Return data for from view employee_list.
    """
    return execute_select_all(curs=cursor, sql="SELECT * FROM employee_list;")


def employee_insert(person_id, customer_id, title, status, email):
    """
     Insert a new employee.

     @param person_id - ID of the person who created the employee.
     @param customer_id - ID of the customer who created the employee.
     @param title - Title of the employee.
     @param status - Employee status ( active deactivated ).
     @param email - Email address of the employee.

     @return ` ` True ` ` if successful

    employee_insert(person_id, customer_id, title, status, email)

    Insert new employe relationship row into table employee
    """
    return execute_sql(
        curs=cursor,
        sql="INSERT INTO employee ( person_id, customer_id, title, status, email, last_user) VALUES (%s, %s, %s, %s, %s, %s);",
        data=(person_id, customer_id, title, status, email, current_user.username),
    )


def employee_list_single(person_id, customer_id):
    """
     Return data for a single employee

     @param person_id - ID of the person who owns the employee
     @param customer_id - ID of the customer for whom to return data

     @return dictionary with data for a

    employee_list_single(person_id, customer_id)

    Return data for single employee from view employee_list.
    """
    return execute_select_one(
        curs=cursor,
        sql="SELECT * FROM employee_list WHERE personid = %s AND customerid = %s LIMIT 1;",
        data=(person_id, customer_id),
    )


def employee_update_db(person_id, customer_id, title, status, email):
    """
     Update employee in the database

     @param person_id - ID of the person who owns the relationship
     @param customer_id - ID of the employee's customer
     @param title - Title of the employee as it appears in the database
     @param status - Status of the employee as it appears in the database
     @param email - Employee's email address

     @return True if successful False

    employee_update_db(person_id, customer_id, title, status, email)

    Update title, status and email of the customer/person relationship.
    """
    return execute_sql(
        curs=cursor,
        sql="UPDATE employee SET title=%s, status=%s, email=%s, last_user=%s WHERE person_id = %s AND customer_id = %s;",
        data=(title, status, email, current_user.username, person_id, customer_id),
    )


def employee_delete_db(person_id, customer_id):
    """
     Delete a person / customer relationship from the employee table

     @param person_id - ID of the person to delete
     @param customer_id - ID of the customer to delete

     @return True if successful False if

    employee_delete_db(person_id, customer_id)

    Delete person/customer relationship from table employee
    """
    return execute_sql(
        curs=cursor,
        sql="DELETE FROM employee WHERE  person_id = %s AND customer_id = %s;",
        data=(person_id, customer_id),
    )


#
# Product -------------------------------------------
def product_list():
    """
     Return data for view products_list.


     @return Dictionary of product data. Example. code - block ::

    product_list()

    Return data for from view products_list.
    """
    return execute_select_all(curs=cursor, sql=("SELECT * FROM products_list;"))


def product_insert(productno, description, longdescription, category):
    """
     Insert a product into the database

     @param productno - product number to be inserted
     @param description - product description ( UTF - 8 encoded )
     @param longdescription - product longdescription ( UTF - 8 encoded )
     @param category - category of the product ( US North America South Civil etc. )

     @return True if successful False if

    product_insert(productno, description, longdescription, category)

    Insert new product into table products
    """
    return execute_sql(
        curs=cursor,
        sql='INSERT INTO products ( "ProductNo", "Description", "LongDescription", "Category", last_user) VALUES (%s, %s, %s, %s, %s);',
        data=(productno, description, longdescription, category, current_user.username),
    )


def product_single(id):
    """
     Return data for single product

     @param id - Product number to retrieve data for

     @return Dictionary with data for single

    product_single(id)

    Return data for single product from table products.
    """
    return execute_select_one(
        curs=cursor,
        sql='SELECT * FROM products WHERE "ProductNo" = %s LIMIT 1;',
        data=(id,),
    )


def product_update_db(id, description, longdescription, category):
    """
     Update a product in the database

     @param id - Product number to update ( int )
     @param description - New description for the product ( str ). Must be less than 128 characters
     @param longdescription - New long description for the product ( str ). Must be less than 512 characters
     @param category - New category for the product ( str ). Must be less than 16 characters

     @return True if successful False if

    product_update_db(id, description, longdescription, category)

    Update product row
    """
    return execute_sql(
        curs=cursor,
        sql='UPDATE products SET "Description"=%s, "LongDescription"=%s, "Category"=%s, last_user=%s WHERE "ProductNo"=%s;',
        data=(description, longdescription, category, current_user.username, id),
    )


def product_delete_db(id):
    """
     Delete a product from the database

     @param id - ID of the product to delete

     @return True if successful False if

    product_delete_db(id)

    Delete product from table products
    """
    return execute_sql(
        curs=cursor, sql='DELETE FROM products WHERE "ProductNo" = %s;', data=(id,)
    )


#
# HELP ------------------
def help_page_db(id):
    """
     Return help text for page.

     @param id - id of page to get help for

     @return list of help text for

    help_page_db(id)

    Return help text for page id from view help_entry.
    """
    return execute_select_one(
        curs=cursor,
        sql="SELECT regexp_matches(%s,page,'g'),help_entry FROM help ORDER BY page DESC",
        data=(id,),
    )


def help_page_list():
    """
     List all pages in help table


     @return a list of page

    help_page_list()

    Return all rows from table help.
    """
    return execute_select_all(curs=cursor, sql="SELECT * FROM help;")


def help_insert_db(id, help_entry):
    """
     Insert a help entry into the database

     @param id - id of the page to insert
     @param help_entry - name of the help entry

     @return whether or not the operation succeded

    help_insert_db(id, help_entry)

    Add a help text to the page (id) in table help.
    """
    return execute_sql(
        curs=cursor,
        sql="INSERT INTO help ( page, help_entry, last_user) VALUES (%s, %s, %s);",
        data=(id, help_entry, current_user.username),
    )


def help_single(id):
    """
     Return data for a single help page

     @param id - id of the help page

     @return dictionary with help data or

    help_single(id)

    Return data for single help page from table help.
    """
    return execute_select_one(
        curs=cursor, sql="SELECT * FROM help WHERE page=%s LIMIT 1;", data=(id,)
    )


def help_update_db(id, help_entry):
    """
    Update help_entry and last_user for page

    @param id - page id to update.
    @param help_entry - new help entry to set.

    @return whether or not the update
    """
    """help_update_db(id, help_entry)

    Update help text for page (id) in table help.
    """
    return execute_sql(
        curs=cursor,
        sql="UPDATE help SET help_entry=%s, last_user=%s WHERE page = %s;",
        data=(help_entry, current_user.username, id),
    )


def help_delete_db(id):
    """
    Delete help entries for a page

    @param id - ID of page to delete

    @return True if successful False if
    """
    """help_delete_db(id)

    Delete help entry for page (id) from table help.
    """
    return execute_sql(curs=cursor, sql="DELETE FROM help WHERE page = %s;", data=(id,))


def inventory_search_db(id=0):
    """
     Search for inventory and return results as a list. This is a wrapper around the inventory_long_list function

     @param id - id of inventory to search

     @return list of search results if id = 0 or None

    inventory_search_db(id)

    Search for string in long inventory view.
    Uses websearch and partial search. You can use oprators like AND, OR, NOT
    in the search expression.
    """

    if id == 0 or id == "" or id is None:
        return inventory_long_list()

    sql = (
        "select * from inventory_long_list "
        + "where to_tsvector("
        + "  coalesce(to_char(inventarna_st, '99999'), ' ') || ' ' ||"
        + "  coalesce(produkt, ' ') || ' ' || "
        + "  coalesce(serijska_st, ' ') || ' ' || "
        + "  coalesce(opis, ' ') || ' ' || "
        + "  coalesce(demo_pool, ' ') || ' ' || "
        + "  coalesce(to_char(reverz_id,'99999'),' ') || ' ' || "
        + "  coalesce(notes, ' ') || ' ' || "
        + "  coalesce(customer_name, ' ') || ' ' || "
        + "  coalesce(customer_person_name, ' ') || ' ' || "
        + "  coalesce(person_name, ' ') || ' ' || "
        + "  coalesce(namen, ' ') || ' ' || "
        + "  coalesce(category, ' ') || ' ' || "
        + "  coalesce(to_char(selectium_asset,'99999'), ' ') || ' ' || "
        + "  coalesce(to_char(demo_start_date::timestamp,'YYYY-MM-DD'), ' ') || ' ' || "
        + "  coalesce(to_char(demo_end_date::timestamp,'YYYY-MM-DD'), ' ') || ' ' || "
        + "  coalesce(to_char(demo_return_date::timestamp,'YYYY-MM-DD'), ' ')) "
        + " @@ to_tsquery('english', websearch_to_tsquery('simple', %s)::text || ':*')"
    )

    return execute_select_all(
        curs=cursor,
        sql=sql,
        data=(id,),
    )
