public with sharing class SeleniumTestCasePerSuite {
	public Selenium_Test_Suite__c obj {get; set;}
	public String TestCaseList {get; set;}
    private ApexPages.StandardController stdController;
    
    public SeleniumTestCasePerSuite(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        this.obj = (Selenium_Test_Suite__c)stdController.getRecord();
    }
      
    public String jsonData {
        get {
        	String q = ApexPages.currentPage().getParameters().get('q');
	    	System.debug('SeleniumTestCasePerSuite.jsonData q='+q);
        	if(q!=null && q!='') {
        		q = '%'+q+'%';
	            return JSON.serialize([SELECT Id, Name FROM Selenium_Test_Case__c WHERE Name like :q ORDER BY LastModifiedDate DESC LIMIT 50]);
        	}
            return JSON.serialize([SELECT Id, Name FROM Selenium_Test_Case__c ORDER BY LastModifiedDate DESC LIMIT 50]);
        }
    }
      
    public String jsonTestcases {
        get {
        	List<Selenium_Test_Case__c> l = new List<Selenium_Test_Case__c>();
	        for(Selenium_Test_Case_Per_Suite__c a : [SELECT Selenium_Test_Case__r.Id, Selenium_Test_Case__r.Name  FROM Selenium_Test_Case_Per_Suite__c WHERE Selenium_Test_Suite__c = :this.obj.Id ORDER BY Order__c, CreatedDate LIMIT 100]) {
	        	l.add(a.Selenium_Test_Case__r);
	        }
	    	System.debug('SeleniumTestCasePerSuite.jsonTestcases length='+l.size());
            return JSON.serialize(l);
        }
    }
    
	public PageReference saveTestCases() {
        Utilities.Secure_DML([select id from Selenium_Test_Case_Per_Suite__c WHERE Selenium_Test_Suite__c = :this.obj.id], Utilities.DML_Action.DEL, schema.Sobjecttype.Selenium_Test_Case_Per_Suite__c);
		if(TestCaseList!=null && TestCaseList.trim()!='') {
			Integer order_no = 1;
			for(String id : TestCaseList.trim().split(' ')) {
				insert new Selenium_Test_Case_Per_Suite__c(Selenium_Test_Suite__c=this.obj.id, Selenium_Test_Case__c=id, Order__c=order_no);
				order_no++;
			}
		}
	    return this.stdController.view();
	}
}