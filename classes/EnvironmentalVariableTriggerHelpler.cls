public class EnvironmentalVariableTriggerHelpler {
    
    public static Map<String,Boolean> MexistingEv {get;set;}
    
    public static void prepareData () {
        
        MexistingEv = new Map<String,Boolean>();
        
        for (Environmental_Variable__c ev :[SELECT Name, Environment__c FROM Environmental_Variable__c]) {
            MexistingEv.put(ev.Name + '' + ev.Environment__c, true);
        }
    }
    
    public static void checkForDuplicates (Environmental_Variable__c evIn) {

        if (MexistingEv.containsKey(evIn.Name + '' + evIn.Environment__c)) {
            evIn.addError(Label.DUPLICATED_ENVIRONMENTAL_VARIABLE);
        }
    }
}