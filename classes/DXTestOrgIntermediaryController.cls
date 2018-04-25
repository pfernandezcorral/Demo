/**
 * Created by ferhatozsavran on 3/14/18.
 */

public with sharing class DXTestOrgIntermediaryController {

    private final Test_Run__c testRun;

    public DXTestOrgIntermediaryController(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()){
            stdController.addFields(new List<String>{'Name'});
        }
        this.testRun = (Test_Run__c)stdController.getRecord();
    }

    public PageReference redirectPage(){
        if(String.isNotBlank(testRun.Name)){
            String orgName = testRun.Name + ' Scratch Org';
            List<Org__c> orgList = [Select Id From Org__c Where Name =: orgName And Org_Type__c = 'Scratch Org - Test Only' And Scratch_Org_Status__c = 'Active' Order By CreatedDate DESC Limit 1];

            if(!orgList.isEmpty()){
                PageReference pRef = Page.DXOperation;
                pRef.getParameters().put('id',orgList.get(0).Id);
                pRef.setRedirect(true);
                return pRef;
            } else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Test_Run_Error));
                return null;
            }
        } else{
            return null;
        }
    }
}