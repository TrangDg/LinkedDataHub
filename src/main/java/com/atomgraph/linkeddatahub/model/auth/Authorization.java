/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.model.auth;

import java.net.URI;
import java.util.Set;
import org.apache.jena.rdf.model.Resource;

/**
 * Authorization interface for access control.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public interface Authorization extends Resource
{
    
    /**
     * Returns authorization modes.
     * 
     * @return mode resources
     */
    Set<Resource> getModes();
    
    /**
     * Returns the URIs of authorization modes
     * 
     * @return mode resource URIs
     */
    Set<URI> getModeURIs();
    
}
