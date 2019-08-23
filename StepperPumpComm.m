function StepperPumpComm(block)
%%
%% The setup method is used to set up the basic attributes of the
%% S-function such as ports, parameters, etc. Do not add any other
%% calls to the main body of the function.
%%
m = [];
sub = [];

setup(block);

%endfunction

%% Function: setup ===================================================
%% Abstract:
%%   Set up the basic characteristics of the S-function block such as:
%%   - Input ports
%%   - Output ports
%%   - Dialog parameters
%%   - Options
%%
%%   Required         : Yes
%%   C-Mex counterpart: mdlInitializeSizes
%%
function setup(block)

    % Register number of ports
    block.NumInputPorts = 3; % dir, start, time
    block.NumOutputPorts = 0;

    % Setup port properties to be inherited or dynamic
    block.SetPreCompInpPortInfoToDynamic;
    block.SetPreCompOutPortInfoToDynamic;

    id = 1;
    block.InputPort(id).Dimensions       = 1;
    block.InputPort(id).DatatypeID  = 0; % double
    block.InputPort(id).Complexity  = 'Real';
    block.InputPort(id).SamplingMode = 'Sample';

    id = 2;
    block.InputPort(id).Dimensions       = 1;
    block.InputPort(id).DatatypeID  = 0; % double
    block.InputPort(id).Complexity  = 'Real';
    block.InputPort(id).SamplingMode = 'Sample';  
    
    id = 3;
    block.InputPort(id).Dimensions       = 1;
    block.InputPort(id).DatatypeID  = 0; % double
    block.InputPort(id).Complexity  = 'Real';
    block.InputPort(id).SamplingMode = 'Sample';
    
    % Register parameters
    block.NumDialogPrms     = 0;

    % Register sample times
    %  [0 offset]            : Continuous sample time
    %  [positive_num offset] : Discrete sample time
    %
    %  [-1, 0]               : Inherited sample time
    %  [-2, 0]               : Variable sample time
    block.SampleTimes = [1 0];

    % Specify the block simStateCompliance. The allowed values are:
    %    'UnknownSimState', < The default setting; warn and assume DefaultSimState
    %    'DefaultSimState', < Same sim state as a built-in block
    %    'HasNoSimState',   < No sim state
    %    'CustomSimState',  < Has GetSimState and SetSimState methods
    %    'DisallowSimState' < Error out when saving or restoring the model sim state
    block.SimStateCompliance = 'DefaultSimState';

    %% -----------------------------------------------------------------
    %% The MATLAB S-function uses an internal registry for all
    %% block methods. You should register all relevant methods
    %% (optional and required) as illustrated below. You may choose
    %% any suitable name for the methods and implement these methods
    %% as local functions within the same file. See comments
    %% provided for each function for more information.
    %% -----------------------------------------------------------------

    block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
    block.RegBlockMethod('InitializeConditions', @InitializeConditions);
    block.RegBlockMethod('Start', @Start);
    block.RegBlockMethod('Outputs', @Outputs);     % Required
    block.RegBlockMethod('Update', @Update);
    block.RegBlockMethod('Derivatives', @Derivatives);
    block.RegBlockMethod('Terminate', @Terminate); % Required

end %setup

%%
%% PostPropagationSetup:
%%   Functionality    : Setup work areas and state variables. Can
%%                      also register run-time methods here
%%   Required         : No
%%   C-Mex counterpart: mdlSetWorkWidths
%%
function DoPostPropSetup(block)
    block.NumDworks = 3;
    id = 1;
    block.Dwork(id).Name            = 'start';
    block.Dwork(id).Dimensions      = 1;
    block.Dwork(id).DatatypeID      = 0;      % double
    block.Dwork(id).Complexity      = 'Real'; % real
    block.Dwork(id).UsedAsDiscState = false;
    id = 2;
    block.Dwork(id).Name            = 'dir';
    block.Dwork(id).Dimensions      = 1;
    block.Dwork(id).DatatypeID      = 0;      % double
    block.Dwork(id).Complexity      = 'Real'; % real
    block.Dwork(id).UsedAsDiscState = false;
    id = 3;
    block.Dwork(id).Name            = 'offtime';
    block.Dwork(id).Dimensions      = 1;
    block.Dwork(id).DatatypeID      = 0;      % double
    block.Dwork(id).Complexity      = 'Real'; % real
    block.Dwork(id).UsedAsDiscState = false;
end %DoPostPropSetup

%%
%% InitializeConditions:
%%   Functionality    : Called at the start of simulation and if it is 
%%                      present in an enabled subsystem configured to reset 
%%                      states, it will be called when the enabled subsystem
%%                      restarts execution to reset the states.
%%   Required         : No
%%   C-MEX counterpart: mdlInitializeConditions
%%
function InitializeConditions(block)

end% InitializeConditions


%%
%% Start:
%%   Functionality    : Called once at start of model execution. If you
%%                      have states that should be initialized once, this 
%%                      is the place to do it.
%%   Required         : No
%%   C-MEX counterpart: mdlStart
%%
function Start(block)
    m = mqtt('tcp://192.168.43.1');
    block.Dwork(1).Data = 0;
    block.Dwork(2).Data = 0;
    block.Dwork(3).Data = 0;
end %Start

%%
%% Outputs:
%%   Functionality    : Called to generate block outputs in
%%                      simulation step
%%   Required         : Yes
%%   C-MEX counterpart: mdlOutputs
%%
function Outputs(block)
end %Outputs

%%
%% Update:
%%   Functionality    : Called to update discrete states
%%                      during simulation step
%%   Required         : No
%%   C-MEX counterpart: mdlUpdate
%%
function Update(block)
    id = 3;
    if block.Dwork(id).Data ~= block.InputPort(id).Data 
        block.Dwork(id).Data = block.InputPort(id).Data;
        publish(m, 'PC1659217/ms', num2str(block.Dwork(id).Data));
    end
    id = 2;
    if block.Dwork(id).Data ~= block.InputPort(id).Data 
        block.Dwork(id).Data = block.InputPort(id).Data;
        publish(m, 'PC1659217/direction', num2str(block.Dwork(id).Data));
    end 
    id = 1;
    if block.Dwork(id).Data ~= block.InputPort(id).Data 
        block.Dwork(id).Data = block.InputPort(id).Data;
        publish(m, 'PC1659217/tps', num2str(block.Dwork(id).Data));
    end


end %Update

%%
%% Derivatives:
%%   Functionality    : Called to update derivatives of
%%                      continuous states during simulation step
%%   Required         : No
%%   C-MEX counterpart: mdlDerivatives
%%
function Derivatives(block)

end %Derivatives

%%
%% Terminate:
%%   Functionality    : Called at the end of simulation for cleanup
%%   Required         : Yes
%%   C-MEX counterpart: mdlTerminate
%%
function Terminate(block)
    publish(m, 'PC1659217/tps', num2str(0));
    disconnect(m);
    delete(m);
end %Terminate

end %All


