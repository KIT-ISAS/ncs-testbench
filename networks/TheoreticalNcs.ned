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

package ncs_testbench.networks;

import inet.networklayer.configurator.ipv6.FlatNetworkConfigurator6;
import libncs_omnet.OracleCC.OracleCCCoordinator;
import inet.node.ipv6.Router6;
import libncs_omnet.NcsInstance;
import libncs_omnet.util.RandomizedChannel;


network TheoreticalNcs
{
    @display("bgb=355,275");

    // Tuneables

    bool useOracleCC = default(false);
    double networkSetupTime @unit("s") = default(20s);
    double ncsStartupDelay @unit("s") = default(30s);

    // NCS network startup delay
    ncs.ncsContext.networkStartupPollInterval = networkSetupTime;

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
        // Configure some routes automagically
        configurator: FlatNetworkConfigurator6 {
            @display("p=45,101");
        }
        // OracleCC managing instance
        oracleCCCoordinator: OracleCCCoordinator if useOracleCC {
            @display("p=45,189");
        }
        // A NCS
        ncs: NcsInstance {
            @display("p=193,109");

            ncsContext.startupDelay = default(ncsStartupDelay);
        }
        router: Router6 {
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
