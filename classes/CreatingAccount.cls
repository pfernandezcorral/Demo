public Class CreatingAccount
{
public Account createAccount(String name)  //method to create account
{

//test to conflict
Account acc = new Account();
acc.Name = name;
acc.newfield__c = 'test';
return acc;
}
}
