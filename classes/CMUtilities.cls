public with sharing class CMUtilities {

    public static Test_Script__c getTestScriptById(String recordId){
        return [SELECT CreatedById, CreatedDate, IsDeleted, Expected_Result__c, Introduction__c, LastModifiedById, LastModifiedDate, Overall_Outcome__c, OwnerId, Peer_Reviewer__c, Prerequisites__c, Project__c, Id, Sprint__c, Status__c, SystemModstamp, Test_Description__c, Name, Test_Title__c, User_Story__c FROM Test_Script__c WHERE Id =:recordId limit 1];
    }
    public static List<Test_Script__c> getTestScripts(Set<Id> thisSet){
        return [SELECT CreatedById, CreatedDate, IsDeleted, Expected_Result__c, Introduction__c, LastModifiedById, LastModifiedDate, Overall_Outcome__c, OwnerId, Peer_Reviewer__c, Prerequisites__c, Project__c, Id, Sprint__c, Status__c, SystemModstamp, Test_Description__c, Name, Test_Title__c, User_Story__c, (SELECT Action_Description__c, CreatedById, CreatedDate, IsDeleted, Expected_Result__c, Guidance_notes__c, LastModifiedById, LastModifiedDate, Order__c, Id, Result__c, Name, Step_Title__c, SystemModstamp, Test_Script__c FROM Script_Steps__r) FROM Test_Script__c WHERE Id =:thisSet limit 1];
    }
    public static List<Test_Script_Step__c> getTestScriptStepsByTest(String testScriptId){
        return [SELECT Action_Description__c, CreatedById, CreatedDate, IsDeleted, Expected_Result__c, Guidance_notes__c, LastModifiedById, LastModifiedDate, Order__c, Id, Result__c, Name, Step_Title__c, SystemModstamp, Test_Script__c FROM Test_Script_Step__c WHERE Test_Script__c =:testScriptId order by Order__c ASC];
    }
    public static List<Test_Run__c> getTestRuns(Set<Id> thisSet){
        return [SELECT Id, Name, Test_Script__c FROM Test_Run__c WHERE Id IN:thisSet];
    }
    public static List<Test_Run_Step__c> getTestRunStepsByTestRun(String testRunId){
        return [SELECT Action_Description__c, Actual_Result__c, CreatedById, CreatedDate, IsDeleted, Expected_Result__c, Guidance_notes__c, LastModifiedById, LastModifiedDate, Id, Script_Step__c, Script_Step__r.Order__c, Status__c, SystemModstamp, Test_Run__c, Name FROM Test_Run_Step__c WHERE Test_Run__c =:testRunId order by Script_Step__r.Order__c ASC];
    }
    public static List<Deployment_Flow_Step__c> getFlowStepsByFlow(String parentId){
        return [SELECT Id, Name, Source_Environment__c, Destination_Environment__c, Deployment_Flow__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :parentId];
    }
}