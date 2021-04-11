///
/// \file Framework/BlockRegistry.hpp
///
/// A BlockRegistry registers a block's factory function.
///
/// \copyright
/// Copyright (c) 2014-2016 Josh Blum
///                    2021 Nicholas Corgan
/// SPDX-License-Identifier: BSL-1.0
///

#pragma once
#include <Pothos/Config.hpp>
#include <Pothos/Callable/Callable.hpp>
#include <Pothos/Proxy/Proxy.hpp>
#include <string>

namespace Pothos {

/*!
 * The BlockRegistry class registers factories for topological elements.
 * These elements include Blocks and sub-Topologies (hierarchies of elements).
 * A BlockRegistry can be created at static initialization time
 * so that modules providing blocks will automatically register.
 * Usage example (put this at the bottom of your c++ source file)
 * static Pothos::BlockRegistry registerMyBlock("/my/factory/path", &MyBlock::make);
 */
class POTHOS_API BlockRegistry
{
public:

    /*!
     * Register a factory function into the plugin registry.
     * The resulting factory path will be /blocks/path.
     * Example: a path of /foo/bar will register to /blocks/foo/bar.
     *
     * Because this call is used at static initialization time,
     * it does not throw. However, registration errors are logged,
     * and the block will not be available at runtime.
     *
     * The return type of the call must be Block* or Topology*.
     *
     * \param path the factory path begining with a slash ("/")
     * \param factory the Callable factory function
     */
    BlockRegistry(const std::string &path, const Callable &factory);

    /*!
     * Instantiate a block given the factory path and arguments.
     * \param path the factory path begining with a slash ("/")
     * \param args a variable number of factory arguments
     * \return the newly created block instance as a Proxy
     */
    template <typename... ArgsType>
    static Proxy make(const std::string &path, ArgsType&&... args);

    /*!
     * Checks if block is registered at a given path.
     * \param path the factory path beginning with a slash ("/")
     * \return whether a block is registered at the given path
     */
    static bool doesBlockExist(const std::string &path);
};

} //namespace Pothos
