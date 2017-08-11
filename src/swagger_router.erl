-module(swagger_router).

-export([get_paths/1]).

-type operations() :: #{
    Method :: binary() => swagger_api:operation_id()
}.

-type init_opts()  :: {
    Operations :: operations(),
    LogicHandler :: atom(),
    ValidatorState :: jesse_state:state()
}.

-export_type([init_opts/0]).

-spec get_paths(LogicHandler :: atom()) ->  [{'_',[{
    Path :: string(),
    Handler :: atom(),
    InitOpts :: init_opts()
}]}].

get_paths(LogicHandler) ->
    ValidatorState = prepare_validator(),
    PreparedPaths = maps:fold(
        fun(Path, #{operations := Operations, handler := Handler}, Acc) ->
            [{Path, Handler, Operations} | Acc]
        end,
        [],
        group_paths()
    ),
    [
        {'_',
            [{P, H, {O, LogicHandler, ValidatorState}} || {P, H, O} <- PreparedPaths]
        }
    ].

group_paths() ->
    maps:fold(
        fun(OperationID, #{path := Path, method := Method, handler := Handler}, Acc) ->
            case maps:find(Path, Acc) of
                {ok, PathInfo0 = #{operations := Operations0}} ->
                    Operations = Operations0#{Method => OperationID},
                    PathInfo = PathInfo0#{operations => Operations},
                    Acc#{Path => PathInfo};
                error ->
                    Operations = #{Method => OperationID},
                    PathInfo = #{handler => Handler, operations => Operations},
                    Acc#{Path => PathInfo}
            end
        end,
        #{},
        get_operations()
    ).

get_operations() ->
    #{ 
        'AddPet' => #{
            path => "/v2/pets",
            method => <<"POST">>,
            handler => 'swagger_pets_handler'
        },
        'DeletePet' => #{
            path => "/v2/pets/:petId",
            method => <<"DELETE">>,
            handler => 'swagger_pets_handler'
        },
        'FindPetsByStatus' => #{
            path => "/v2/pet/findByStatus",
            method => <<"GET">>,
            handler => 'swagger_pets_handler'
        },
        'FindPetsByTags' => #{
            path => "/v2/pets/findByTags",
            method => <<"GET">>,
            handler => 'swagger_pets_handler'
        },
        'GetPetById' => #{
            path => "/v2/pets/:petId",
            method => <<"GET">>,
            handler => 'swagger_pets_handler'
        },
        'UpdatePet' => #{
            path => "/v2/pets",
            method => <<"PUT">>,
            handler => 'swagger_pets_handler'
        },
        'UpdatePetWithForm' => #{
            path => "/v2/pets/:petId",
            method => <<"POST">>,
            handler => 'swagger_pets_handler'
        },
        'UploadFile' => #{
            path => "/v2/pets/:petId/uploadImage",
            method => <<"POST">>,
            handler => 'swagger_pets_handler'
        },
        'DeleteOrder' => #{
            path => "/v2/stores/orders/:orderId",
            method => <<"DELETE">>,
            handler => 'swagger_stores_handler'
        },
        'GetInventory' => #{
            path => "/v2/stores/inventory",
            method => <<"GET">>,
            handler => 'swagger_stores_handler'
        },
        'GetOrderById' => #{
            path => "/v2/stores/orders/:orderId",
            method => <<"GET">>,
            handler => 'swagger_stores_handler'
        },
        'PlaceOrder' => #{
            path => "/v2/stores/orders",
            method => <<"POST">>,
            handler => 'swagger_stores_handler'
        },
        'CreateUser' => #{
            path => "/v2/users",
            method => <<"POST">>,
            handler => 'swagger_users_handler'
        },
        'CreateUsersWithArrayInput' => #{
            path => "/v2/users/createWithArray",
            method => <<"POST">>,
            handler => 'swagger_users_handler'
        },
        'CreateUsersWithListInput' => #{
            path => "/v2/users/createWithList",
            method => <<"POST">>,
            handler => 'swagger_users_handler'
        },
        'DeleteUser' => #{
            path => "/v2/users/:username",
            method => <<"DELETE">>,
            handler => 'swagger_users_handler'
        },
        'GetUserByName' => #{
            path => "/v2/users/:username",
            method => <<"GET">>,
            handler => 'swagger_users_handler'
        },
        'LoginUser' => #{
            path => "/v2/users/login",
            method => <<"GET">>,
            handler => 'swagger_users_handler'
        },
        'LogoutUser' => #{
            path => "/v2/users/logout",
            method => <<"GET">>,
            handler => 'swagger_users_handler'
        },
        'UpdateUser' => #{
            path => "/v2/users/:username",
            method => <<"PUT">>,
            handler => 'swagger_users_handler'
        }
    }.

prepare_validator() ->
    R = jsx:decode(element(2, file:read_file(get_swagger_path()))),
    jesse_state:new(R, [{default_schema_ver, <<"http://json-schema.org/draft-04/schema#">>}]).


get_swagger_path() ->
    {ok, AppName} = application:get_application(?MODULE),
    filename:join(swagger_utils:priv_dir(AppName), "swagger.json").


