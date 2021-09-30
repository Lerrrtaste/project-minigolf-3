extends Node

var GA
var ready := false

func setup(user_id:String) -> bool:
	_ga_configure(user_id)
	_ga_initialize()
	return true


func _ga_configure(user_id:String) -> void:
	if Engine.has_singleton("GameAnalytics"):
		GA = Engine.get_singleton("GameAnalytics")
	
	if Global.DEBUGGING:
		GA.setEnabledInfoLog(true)
		GA.setEnabledVerboseLog(true)
	
	GA.configureBuild(Global.VERSION)
	GA.configureUserId(user_id)
	GA.configureAvailableResourceCurrencies(Global.GA_ALLOWED_CURRENCIES)
	GA.configureAvailableResourceItemTypes(Global.GA_ALLOWED_ITEMTYPE);
	GA.setEnabledEventSubmission(Global.GA_ENABLE_EVENT_SUBMISSION);


func _ga_initialize() -> void:
	GA.init(Global.GA_GAME_KEY,Global.GA_SECRET_KEY)
	
	ready = true #TODO implement actual check


#maybe via signel (connected on game start by match node)
func event_match_started(map_id:String)->void:
	assert(ready)
	
	GA.addProgressionEvent({
	"progressionStatus": "Start", #only start/fail/complete
	"progression01": "test_map_pack",
	"progression02": map_id,
	})

func event_match_completed(map_id:String, score) -> void:
	assert(ready)
	
	GA.addProgressionEvent({
	"progressionStatus": "Complete", #only start/fail/complete
	"progression01": "test_map_pack",
	"progression02": map_id,
	"score": -1,
	})

func event_error(severity:String,message:String)->void:
	GA.addErrorEvent({
		"severity": "Info", #Debug,Info,Warning,Error,Critical
		"message": "Something went bad in some of the smelly code!",
	})
