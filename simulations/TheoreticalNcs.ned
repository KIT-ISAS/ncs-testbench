//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
// 

package ncs_testbench.simulations;

import inet.networklayer.configurator.ipv4.IPv4NetworkConfigurator;
import inet.node.inet.Router;
import libncs_omnet.NcsInstance;
import libncs_omnet.NcsManager;
import libncs_omnet.util.RandomizedChannel;


network TheoreticalNcs
{
    @display("bgb=355,275");
    types:
        channel ActorLink extends RandomizedChannel
        {
            @defaultname("actorLink");
        }
        channel SensorLink extends RandomizedChannel
        {
            @defaultname("sensorLink");
        }
    submodules:
        // Responsible to set up the MATLAB part of the simulation 
        NcsManager: NcsManager {
            @display("p=45,39");
        }
        // Configure some routes automagically
        configurator: IPv4NetworkConfigurator {
            @display("p=45,101");
        }
        // A NCS
        ncs: NcsInstance {
            @display("p=193,109");
        }
        router: Router {
            @display("p=191,203");
        }
    connections:
        // Each NCS has one connection for Actor, Controller an Sensor.
        // The graphical rendering looks a bit odd, but the scenario can be setup and configured easier this way
        ncs.gActor <--> ActorLink <--> router.pppg++;
        // use RandomizedChannel with no drops instead of an IdealChannel since INET insists on a TransmissionChannel
        // modeled with no delay
        ncs.gController <--> RandomizedChannel {  pdf = "0:1"; } <--> router.pppg++;
        ncs.gSensor <--> SensorLink <--> router.pppg++;
}
