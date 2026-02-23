from flask_wtf import FlaskForm, Form
from wtforms import StringField, PasswordField, SubmitField, BooleanField, TextAreaField
from wtforms import (
    SelectField,
    DateField,
    FieldList,
    FormField,
    HiddenField,
    IntegerField,
)
from wtforms.validators import Length, EqualTo, Email, DataRequired, ValidationError
from reverz import cursor
from reverz.db_queries import reverz_list_single, inventory_active
from flask_ckeditor import CKEditorField


class IzdajaForm(FlaskForm):
    def validate_reverz_id(form, field):
        (status, reverz) = reverz_list_single(field.data)
        return reverz is not None and status

    reverz_id = StringField(label="Številka reverza:", validators=[DataRequired()])
    submit = SubmitField(label="Submit")


class CustomerForm(FlaskForm):
    name = StringField(
        label="Stranka", validators=[Length(min=2, max=256), DataRequired()]
    )
    address = TextAreaField(
        label="Naslov", validators=[Length(max=512), DataRequired()]
    )
    active = BooleanField(label="Aktiven")
    submit = SubmitField(label="Shrani")


class CategoryForm(FlaskForm):
    id = StringField(
        label="Kategorija", validators=[Length(min=1, max=16), DataRequired()]
    )
    description = TextAreaField(
        label="Opis", validators=[Length(max=256), DataRequired()]
    )
    submit = SubmitField(label="Shrani")


class PersonForm(FlaskForm):
    name = StringField(
        label="Ime in priimek", validators=[Length(min=2, max=64), DataRequired()]
    )
    email = StringField(label="Osebni Email", validators=[Length(max=128), Email()])
    phone = StringField(label="Telefon", validators=[Length(max=16)])
    submit = SubmitField(label="Shrani")


class DemopoolForm(FlaskForm):
    id = StringField(
        label="Demo pool", validators=[Length(min=2, max=64), DataRequired()]
    )
    description = TextAreaField(
        label="Opis", validators=[Length(max=128), DataRequired()]
    )
    for_sale = BooleanField(label="Za nadalnjo prodajo")
    submit = SubmitField(label="Shrani")


class ProductForm(FlaskForm):
    productno = StringField(
        label="Produktna številka (Part No)",
        validators=[Length(min=5, max=16), DataRequired()],
    )
    description = StringField(label="Naziv", validators=[Length(max=128)])
    longdescription = TextAreaField(label="Podroben opis", validators=[Length(max=512)])
    category = SelectField(label="Kategorija", choices=[])
    submit = SubmitField(label="Shrani")


class EmployeeForm(FlaskForm):
    person_id = SelectField(label="Oseba", choices=[], validators=[DataRequired()])
    customer_id = SelectField(label="Stranka", choices=[], validators=[DataRequired()])
    title = StringField(label="Službeni naziv", validators=[Length(max=128)])
    email = StringField(label="Službeni Email", validators=[Length(max=128), Email()])
    status = BooleanField(label="Aktiven")
    submit = SubmitField(label="Shrani")


class ReverzSelectForm(FlaskForm):
    id = SelectField(label="Stranka", choices=[])
    submit = SubmitField(label="Create")


class ReverzEditItemForm(FlaskForm):
    part_no = StringField(label="Produkt")
    description = StringField(label="Naziv")
    serial_no = StringField(label="Serijska št.")
    demo_start_date = DateField(label="Datum izdaje")
    demo_end_date = DateField(label="Izdano do")
    demo_return_date = DateField(label="Vrnjeno dne")
    namen = TextAreaField(label="Namen testiranja", validators=[Length(max=8192)])
    notes = TextAreaField(label="Opombe", validators=[Length(max=1024)])
    submit = SubmitField(label="Shrani")


def reverz_items_add(inventory):
    item_name_list = []
    for item in inventory:
        item_name_list.append(str(item["inventarna_st"]))
    return item_name_list


def reverz_set_items_field(items_form, item_name_list):
    for inv_st in item_name_list:
        setattr(items_form, str(inv_st), BooleanField(label=str(inv_st)))


class ReverzCreateForm(FlaskForm):
    customer_person_id = SelectField(label="Prevzel", choices=[])
    person_id = SelectField(label="Izdal", choices=[])
    description = TextAreaField(
        label="Namen testiranja", validators=[Length(max=512), DataRequired()]
    )
    demo_start_date = DateField(label="Datum izdaje", validators=[DataRequired()])
    demo_end_date = DateField(label="Izdano do", validators=[DataRequired()])
    active = BooleanField(label="Aktiven")
    submit = SubmitField(label="Create")


class ReverzEditForm(FlaskForm):
    id = StringField(label="Reverz #")
    stranka = StringField(label="Stranka")
    customer_id = StringField(label="Koda stranke")
    customer_person_id = SelectField(label="Prevzel", choices=[])
    person_id = SelectField(label="Izdal", choices=[])
    description = TextAreaField(
        label="Namen testiranja", validators=[Length(max=512), DataRequired()]
    )
    demo_start_date = DateField(label="Datum izdaje", validators=[DataRequired()])
    demo_end_date = DateField(label="Izdano do", validators=[DataRequired()])
    demo_return_date = DateField(label="Vrnjeno dne")
    active = BooleanField(label="Aktiven")
    demo_result = TextAreaField(
        label="Rezultat testiranja", validators=[Length(max=512)]
    )
    modified_by = StringField(label="Zadnja sprememba")
    submit = SubmitField(label="Shrani")

    def getField(self, fieldName):
        for f in self:
            if f.name in str(fieldName):
                return f
        return None


class ReverzCloseForm(FlaskForm):
    reverz_id = HiddenField()
    demo_result = TextAreaField(
        label="Rezultat testiranja", validators=[Length(max=512)]
    )
    submit = SubmitField(label="Zaključi reverz")


class InventoryForm(FlaskForm):
    id = StringField(label="Inv #")
    product_no = SelectField(
        label="Produktna številka (Part No)", choices=[], validators=[DataRequired()]
    )
    serial_no = StringField(
        label="Serijska številka (Serial No)", validators=[Length(max=16)]
    )
    available = BooleanField(label="Za izposojo")
    demo_pool = SelectField(label="Demo pool", choices=[], validators=[DataRequired()])
    notes = TextAreaField(label="Opombe", validators=[Length(max=256)])
    selectium_asset = IntegerField(label="Selectium Inventarna Številka")
    submit = SubmitField(label="Shrani")


class HelpForm(FlaskForm):
    page = StringField(
        label="Stran za pomoč", validators=[Length(max=64), DataRequired()]
    )
    help_entry = CKEditorField(label="Besedilo pomoči", validators=[DataRequired()])
    current_page = BooleanField(label="Osnovna stran pomoči")
    submit = SubmitField(label="Shrani")


class LoginForm(FlaskForm):
    username = StringField(
        label="Username:", validators=[Length(min=4, max=12), DataRequired()]
    )
    password = PasswordField(
        label="Password:", validators=[Length(min=4, max=16), DataRequired()]
    )
    submit = SubmitField(label="Log in")


class LoginForm(FlaskForm):
    username = StringField(
        "Username", validators=[DataRequired(), Length(min=1, max=50)]
    )
    password = PasswordField("Password", validators=[DataRequired(), Length(min=4)])
    submit = SubmitField("Login")


class InventorySearchForm(FlaskForm):
    search = StringField(label="Search", placeholder="Search")
    submit = SubmitField(label="Search")
