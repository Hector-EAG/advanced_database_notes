Create a trigger that fires before inserting each row in the PET_CARE_LOG table. The trigger will assign the current data and time to the UPDATE_DATE column. It will also assign the current user to the UPDATED_BY_USER column. Use pseudocolumns to get the values that you need. Handle all errors in one general exception handler and send an error message using the RAISE_APPLICATION_ERROR procedure.
Create a trigger that fires before updating each row of the PET_CARE_LOG table. This trigger will look at the current user and compare it with the value in the UPDATED_BY_USER column. If the two are the same, the update proceeds. If they are different, the update raises an exception and fails. Handle any other database errors the same way you did in the insert trigger.
Create a trigger that fires before any row is deleted from the PET_CARE_LOG table. This trigger looks at the user who is deleting the row. If the user is ‘JOEMANAGER,’ the delete continues successfully. Otherwise, the delete fails and sends an error message. Handle any other database errors the same way you did in the insert trigger.
 

schema

https://www.relationaldbdesign.com/programming-plsql/module1/database-pet-store-schema.php