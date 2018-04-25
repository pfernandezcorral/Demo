public with sharing class KanbanBoard {
    private Kanban_Board__c obj;
    private Map<String, String> myMap;

    public KanbanBoard(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String> {
                'Name',
                'SOQL_Query__c',
                'Field_to_read_update__c',
                'Description__c',
                'Columns_SOQL__c',
                'JSON_Settings__c'
            });
        }
        this.obj = (Kanban_Board__c)stdController.getRecord();        
        getJSonRecord();
    }

    public String getJSonRecord() {
        // NOTE: needed due to namespacing
        if (myMap != null) {
            return JSON.serialize(myMap);
        } else {
            myMap = new Map<String, String> {
                'Id' => obj.Id,
                'Name' => obj.Name,
                'SOQL_Query__c' => obj.SOQL_Query__c,
                'Field_to_read_update__c' => obj.Field_to_read_update__c,
                'JSON_Settings__c' => obj.JSON_Settings__c,
                'Columns_SOQL__c' => obj.Columns_SOQL__c,
                'Description__c' => obj.Description__c
            };

            return JSON.serialize(myMap);
        }
    }
}