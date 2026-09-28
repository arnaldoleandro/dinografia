local Cycle = {}
Cycle.__index = Cycle

--- Creates the timed door cycle independently of physics and rendering.
function Cycle.new(signalSeconds, moveSeconds, openSeconds)
    return setmetatable({state="Closed", deadline=math.huge, signal=signalSeconds,
        move=moveSeconds, hold=openSeconds, released=false},Cycle)
end

--- Requests opening without restarting an opening already in progress.
function Cycle:Open(now)
    if self.state=="Open" then self.deadline=now+self.hold
    elseif self.state=="Closed" then self.state="Signalling";self.deadline=now+self.signal
    elseif self.state=="Closing" then self.state="Opening";self.deadline=now+self.move end
    return self.state
end

--- Advances one transition, reopening whenever the closing area is occupied.
function Cycle:Step(now,occupied)
    if self.state=="Closing" and occupied then
        self.state="Opening";self.deadline=now+self.move
    elseif now>=self.deadline then
        if self.state=="Signalling" then self.state="Opening";self.deadline=now+self.move
        elseif self.state=="Opening" then self.state="Open";self.deadline=now+self.hold;self.released=true
        elseif self.state=="Open" and not occupied then self.state="Closing";self.deadline=now+self.move
        elseif self.state=="Closing" then self.state="Closed";self.deadline=math.huge end
    end
    return self.state
end

--- Allows a new tracing session only while the door is fully closed.
function Cycle.CanWrite(state)
    return state=="Closed" or state=="Locked"
end
return Cycle