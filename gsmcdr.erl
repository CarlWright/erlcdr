-module (gsmcdr).
-export ([init/1, process/2]).
-vsn(0.9).

init (Outfile) ->
    file:open(Outfile, [write]).

process(Rec, Out)  ->
    ModuleFlag = case lists:sublist(Rec, 9,1) of
		     "0" -> false;
		     "1" -> true
		 end,
    case lists:sublist(Rec, 10, 4) of
	"0001" -> cdrStrip(locationUpdate, Rec, ModuleFlag, 256, false, Out);
	"0002" -> cdrStrip(mobileOriginated, Rec, ModuleFlag, 392, true, Out);
	"0003" -> cdrStrip(mobileTerminated, Rec, ModuleFlag, 358, true, Out);
	"0004" -> cdrStrip(smsMobileOriginated, Rec, ModuleFlag, 302, true, Out);
	"0005" -> cdrStrip(smsMobileTerminated, Rec, ModuleFlag, 276, true, Out);
	"0006" -> cdrStrip(supplementaryServiceAction, Rec, ModuleFlag, 246, false, Out);
	"0007" -> cdrStrip(tranferIn, Rec, ModuleFlag, 78, false, Out);
	"0008" -> cdrStrip(transferOut, Rec, ModuleFlag, 98, false, Out);
	"0009" -> cdrStrip(timeChange, Rec, ModuleFlag, 86, false, Out);
	"0010" -> cdrStrip(switchRestart, Rec, ModuleFlag, 72, false, Out);
	"0011" -> cdrStrip(blockHeader, Rec, ModuleFlag, 64, false, Out);
	"0013" -> cdrStrip(incomingGateway, Rec, ModuleFlag, 248, false, Out);
	"0014" -> cdrStrip(outgoingGateway, Rec, ModuleFlag, 248, false, Out);
	"0015" -> cdrStrip(incomingIntraPLMNTrunk, Rec, ModuleFlag, 248, false, Out);
	"0016" -> cdrStrip(outgoingIntraPLMNTrunk, Rec, ModuleFlag, 248, false, Out);
	"0017" -> cdrStrip(transit, Rec, ModuleFlag, 248, false, Out);
	"0018" -> cdrStrip(roaming, Rec, ModuleFlag, 328, false, Out);
	"0019" -> cdrStrip(commonEquipmentUsage, Rec, ModuleFlag, 180, false, Out);
	"0020" -> cdrStrip(acknowledgement, Rec, ModuleFlag, 206, false, Out);
	"0021" -> cdrStrip(locationServices, Rec, ModuleFlag, 332, false, Out)
    end.

cdrStrip(_Type, Record, ModuleFlag, Length, Output, Out) -> 
    case ModuleFlag of 
	false -> CDR = Record, Modules = [];
	true  -> {CDR, Modules} = lists:split(Length,Record)
    end,
    _Mods = parse_modules(Modules),
    if Output == true -> io:format(Out,"~s~n",[CDR]);
       true -> []
    end. 


parse_modules(Modules) ->
    cut_modules(Modules,[]).

cut_modules(Modules,Parsed) ->
    case lists:sublist( Modules, 2, 2) of
	"00" -> [Parsed | {end_of_modules,lists:sublist(Modules, 4)} ];
	"02" -> cutter(24,  Modules, Parsed, bearer_service);
	"03" -> cutter(126, Modules, Parsed, location_and_channel);
	"05" -> cutter(62,  Modules, Parsed, supplementary_services);
	"06" -> cutter(24,  Modules, Parsed, teleservices);
	"07" -> cutter(70,  Modules, Parsed, aoc_parameter);
	"08" -> cutter(22,  Modules, Parsed, tariff_class);
	"09" -> cutter(72,  Modules, Parsed, dataservice);
	"10" -> cutter(20,  Modules, Parsed, other_agent);
	"04" -> cutter(52,  Modules, Parsed, location_only);
	"11" -> cutter(92,  Modules, Parsed, module_11);
	"12" -> cutter(36,  Modules, Parsed, equal_access);
	"13" -> cutter(26,  Modules, Parsed, partial);
	"16" -> cutter(8,   Modules, Parsed, trunk_usage);
	"18" -> cutter(224, Modules, Parsed, in_info);
	"19" -> cutter(142, Modules, Parsed, in_charging);
	"20" -> cutter(84,  Modules, Parsed, generic_address);
	"21" -> cutter(54,  Modules, Parsed, module_21);
	"22" -> cutter(50,  Modules, Parsed, network_call_reference);
	"23" -> cutter(358, Modules, Parsed, camel_charging);
	"25" -> cutter(34,  Modules, Parsed, mobile_number_portability);
	"26" -> cutter(140, Modules, Parsed, gsm_assisting_ssp);
	"27" -> cutter(214, Modules, Parsed, camel_sms);
	"28" -> cutter(116, Modules, Parsed, patching)  
    end.

cutter(Length, Modules, Parsed, Type) ->
    {Mod, Rest} = lists:split(Length, Modules),  
    cut_modules( Rest, [Parsed | {Type, Mod}]).


