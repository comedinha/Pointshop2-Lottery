Pointshop2.PslModel = class( "Pointshop2.PslModel" )

Pointshop2.PslModel.static.DB = "Pointshop2" --The identifier of the database as given to LibK.SetupDatabase
Pointshop2.PslModel.static.model = {
    tableName = "ps2_psl",
    fields = {
        ownerId = "int",
        filename = "string",
        count = "int"
	}
}
Pointshop2.PslModel:include( DatabaseModel ) --Adds the model functionality and automagic functions
