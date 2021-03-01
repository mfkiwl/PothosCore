///
/// \file Proxy/ProxyImpl.hpp
///
/// Proxy template method implementations.
///
/// \copyright
/// Copyright (c) 2013-2017 Josh Blum
///                    2021 Nicholas Corgan
/// SPDX-License-Identifier: BSL-1.0
///

#pragma once
#include <Pothos/Config.hpp>
#include <Pothos/Object/ObjectImpl.hpp>
#include <Pothos/Proxy/Proxy.hpp>
#include <Pothos/Proxy/Handle.hpp>
#include <Pothos/Proxy/Environment.hpp>
#include <type_traits> //enable_if
#include <utility> //std::forward
#include <cassert>
#include <array>

namespace Pothos {

template <typename ValueType>
ValueType Proxy::convert(void) const
{
    return this->getEnvironment()->convertProxyToObject(*this).convert<ValueType>();
}

namespace Detail {

/***********************************************************************
 * convertProxy either converts a proxy to a desired type
 * or returns a proxy if the requested type was a proxy
 **********************************************************************/
template <typename T>
typename std::enable_if<!std::is_same<T, Proxy>::value, T>::type
convertProxy(const Proxy &p)
{
    return p.convert<T>();
}

template <typename T>
typename std::enable_if<std::is_same<T, Proxy>::value, T>::type
convertProxy(const Proxy &p)
{
    return p;
}

/***********************************************************************
 * makeProxy either makes a proxy from an arbitrary type
 * or returns a proxy if the type is already a proxy
 **********************************************************************/
template <typename T>
typename std::enable_if<!std::is_same<typename std::decay<T>::type, Proxy>::value, Proxy>::type
makeProxy(const ProxyEnvironment::Sptr &env, T &&value)
{
    return env->makeProxy(std::forward<T>(value));
}

template <typename T>
typename std::enable_if<std::is_same<typename std::decay<T>::type, Proxy>::value, Proxy>::type
makeProxy(const ProxyEnvironment::Sptr &, T &&value)
{
    // Explicitly copy the input proxy. This removes a Clang warning that says
    // that this happens anyway. Since the proxy class only stores a shared_ptr
    // to the implementation, this operation is cheap.
    return T(value);
}

} //namespace Detail

template <typename ValueType>
Proxy::operator ValueType(void) const
{
    return this->convert<ValueType>();
}

template <typename ReturnType, typename... ArgsType>
ReturnType Proxy::call(const std::string &name, ArgsType&&... args) const
{
    Proxy ret = this->call(name, std::forward<ArgsType>(args)...);
    return Detail::convertProxy<ReturnType>(ret);
}

template <typename... ArgsType>
Proxy Proxy::call(const std::string &name, ArgsType&&... args) const
{
    const std::array<Proxy, sizeof...(ArgsType)> proxyArgs{{Detail::makeProxy(this->getEnvironment(), std::forward<ArgsType>(args))...}};
    auto handle = this->getHandle();
    assert(handle);
    return handle->call(name, proxyArgs.data(), sizeof...(args));
}

template <typename... ArgsType>
Proxy Proxy::callProxy(const std::string &name, ArgsType&&... args) const
{
    return this->call(name, std::forward<ArgsType>(args)...);
}

template <typename... ArgsType>
void Proxy::callVoid(const std::string &name, ArgsType&&... args) const
{
    this->call(name, std::forward<ArgsType>(args)...);
}

template <typename ReturnType>
ReturnType Proxy::get(const std::string &name) const
{
    return this->call<ReturnType>("get:"+name);
}

template <typename ValueType>
void Proxy::set(const std::string &name, ValueType&& value) const
{
    this->call("set:"+name, std::forward<ValueType>(value));
}

template <typename... ArgsType>
Proxy Proxy::operator()(ArgsType&&... args) const
{
    return this->call("()", std::forward<ArgsType>(args)...);
}

} //namespace Pothos
