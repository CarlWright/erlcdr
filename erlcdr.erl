-module (erlcdr).
-export ([init/0,process/2]).
-vsn(0.9).


init() -> OFL = io:get_line("Output Filename: "),
          OFL2 = lists:sublist( OFL , length(OFL) - 1),
          OFL3 =  file:open(OFL2, [write]),
	  case  OFL3 of
              {ok, Outfile}   -> 
		  IFL = io:get_line("Input Filename: "),
		  Filename = lists:sublist( IFL , length(IFL) - 1),
		  io:format("Start at ~w~n",[time()]),
		  case  file:open(Filename, [raw, binary, read]) of
		      {ok, Infile}    -> process( {Infile, Outfile}, file:read(Infile, 2048));
		      {error, Reason} -> io:format(" Problem with input file: ~s~n",[file:format_error(Reason)]),
					 exit(Reason)
		  end,
		  ok;
	      {error, Reason} -> io:format(" Problem with output file: ~s~n",[file:format_error(Reason)]),
				 exit(Reason)
	  end.

%% main processing loop for the entire file.
%%
process( {F,Out}, {ok, Block} ) ->      parse_block(Block, Out),
                                        process({F, Out}, file:read(F, 2048));
process( {F,Out},  eof  )       ->      file:close(F),
                                        file:close(Out),
                                        io:format("End at ~w~n",[time()]);
process( {F,Out},{error, Reason} )  ->  file:close(F),
                                        file:close(Out),
                                        io:format("End at ~w~n",[time()]),
                                        {error, Reason}.

%% break a block into the space holding records.
parse_block( Block, Out ) ->
    <<BDW:16, _:16, Rest/binary>> = Block,
    {Remainder, _} = lists:split((BDW - 4), binary_to_list(Rest)),
    record_parse(list_to_binary(Remainder), Out).

%% break the space holding records into individual records.  
record_parse(<<>>, _Out) -> 0;
record_parse( Records, Out) ->
    <<RDW:16, _:16, Rest/binary>> = Records,
    {Rec, OtherRecs} = lists:split( (RDW - 4), binary_to_list(Rest) ),
    process_record(Rec, Out),
    record_parse(list_to_binary(OtherRecs), Out).

%% process a record 
process_record(Record, Out) ->
    CDR = bcd_to_ascii(Record), 
    gsmcdr:process(CDR, Out).

%% take a binary of BCD characters and get them into an ASCII list.  
bcd_to_ascii([]) -> [];
bcd_to_ascii(String) -> 
    BCD1 = << <<X:8>> || <<X:4>> <= list_to_binary(String) >>,
    BCD = binary_to_list(BCD1),
    asciiShift( BCD).

%% take BCD in 8 bit bytes and move them to visible ASCII values.
asciiShift([H|T]) -> [case H < 10 of  true  -> H + 48;  false -> H + 55  end|asciiShift(T)];
asciiShift([])    -> [].
