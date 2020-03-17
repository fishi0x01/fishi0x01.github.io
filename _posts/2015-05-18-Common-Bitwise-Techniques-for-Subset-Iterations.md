---
layout: post
title:  "Common Bitwise Techniques for Subset Iterations"
date:   2015-05-18 22:00:44 +0000
modified: 2015-06-19 12:03:12 +0000 
comments: true
disqus_id: 8
permalink: weblog/2015/05/18/common-bitwise-techniques-subset-iterations/
categories: algorithm python
---

{% include tags/math.html %}

Some problems, especially in combinatorics require to iterate over subsets of a given 1-dimensional array with \\(N\\) elements. 
There are different ways to approach this topic, but the most common and elegant solutions in my opinion involve bitwise operations. 
{: .text-justify}

I recently stumbled across a problem that required me to iterate over the [Power set][wiki-powerset] of an array, which is why now I want to discuss some common bitwise techniques<!--more--> that are used to iterate over:
{: .text-justify}

* each subset ([Power set][wiki-powerset]).
* subsets of a certain size \\(K \le N\\).
* subsets of sizes \\(X\\), \\(X \le K \le N\\).
{: .text-justify}

## Iterate over each subset of any size (Power set) ##

We are given an array with \\(N\\) elements and we want to iterate over each subset of any size \\(K\\), \\(0 \le K \le N\\). 
This is also called a [Power set][wiki-powerset]. 
We know that the number of all the subsets is equal to \\(2^N\\). 
Binary numbers are unique combinations of 1's and 0's and a binary number with \\(N\\) digits can represent any decimal integer between \\(0\\) and \\(2^N - 1\\). 
Thanks to that, we could represent each unique subset with a unique binary number. 
Lets choose array {4,5,7} as an example, then we have to represent \\(2^3 = 8\\) subsets:
{: .text-justify}

<pre>
 0 0 0    0 0 1   
{     }  {    7}  

 0 1 0    0 1 1
{  5  }  {  5,7}

 1 0 0    1 0 1    
{4    }  {4,  7} 

 1 1 0    1 1 1
{4,5  }  {4,5,7}
</pre>

Now lets put this thought in python code:
{: .text-justify}

{% gist fishi0x01/b21195c7fd75a191c0cd power_set.py %}

`1 << N` simply means shifting the 1 bit \\(N\\) positions to the left, which equals \\(2^N\\) in decimal (still bit shift operations are much cheaper than multiple arithmetic multiplications). 
We use each binary digit of our `mask` as a flag which indicates whether an array's index is part of the current subset or not. 
With `((mask >> n)&1)` we get a hold of the \\(n\\)th bit from the right of `mask`. 
{: .text-justify}

{% include tags/hint-start.html %}
Note, that since we are iterating over \\(2^N\\) subsets this algorithm has exponential time complexity and thus is very slow for big \\(N\\)!
{: .text-justify}
{% include tags/hint-end.html %}

## Iterate over subsets of size exactly \\(K\\) ##

Now what if we only want to find all the subsets of a fixed size \\(K\\), \\(0 \le K \le N\\)? 
{: .text-justify}

Sure, we could do the same as before and only append our subset to the result list, if it has exactly \\(K\\) elements. 
The issue here is, that in other problems we might want to know instantly whether an element is part of the current subset (to start doing some work with it) before we found all of the other elements of the same subset. 
Thus, we need another more elegant approach. 
{: .text-justify}

Lets take the array {4,5,7,9} as an example and we want to find all subsets of size \\(K=2\\). 
Then we get:
{: .text-justify}

<pre>
 0 0 1 1    0 1 0 1   
{    7,9}  {  5,  9}  

 1 0 0 1    1 0 1 0 
{4,    9}  {4,  7  }

 1 1 0 0    0 1 1 0
{4,5    }  {  5,7  }
</pre>

We can easily see that the problem could also be formulated as finding all the decimal masks \\(M\\), \\(0 \le M \le K^2-1\\), that have exactly \\(K\\) bits set to 1 in their binary representation. 
An algorithm called Gosper's hack can be used to solve this problem: 
{: .text-justify}

* First extract the rightmost 1 bit of the current mask.
* Next, set the last non-trailing bit to 0 and clear to the right (carry bit).
* Finally, produce a block of 1s at the least-significant bit.
{: .text-justify}

Here is how that would look like in python:
{: .text-justify}

{% gist fishi0x01/b21195c7fd75a191c0cd subsets_eq_k.py %}

The approach is very similar to the one we previously used for determining the Power set. 
The only major difference is that we do not simply increment our mask by 1 each iteration, but instead use Gosper's hack to find the next mask with exactly the same amount of 1 bits. 
{: .text-justify}

{% include tags/hint-start.html %}
Again this is an expensive algorithm. 
In the Power set case we were looking for \\(2^N\\) subsets. 
Further, the [binomial theorem](https://en.wikipedia.org/wiki/Binomial_theorem) states that \\((1+x)^n = \sum\limits_{k=0}^n {n \choose k} x^k\\). 
In this case (for \\(x=1\\)) we can translate that to \\(2^N = \sum\limits_{K=0}^N {N \choose K} \\). 
{: .text-justify}

In words this means that the binomial coefficient \\(N \choose K\\) is the number of subsets of size \\(K\\) in a set of \\(N\\) elements. 
Thus, the sum of all subsets of any size \\(K, 1 \leq K \leq N\\) is the amount of subsets in the Power set (which is \\(2^N\\)). 
Hence, when looking for subsets of size exactly \\(K\\) the algorithm iterates over \\(N \choose K\\) subsets.
{: .text-justify}
{% include tags/hint-end.html %}

## Iterate over subsets of sizes \\(\le K\\) ##

Finally, lets iterate over all the subsets of size \\(X\\), \\(0 \le X \le K\\). 
The approach here is very similar to the one before, we simply have to modify our way of how to determine the next mask in each loop.
{: .text-justify}

Here some python code again:
{: .text-justify}

{% gist fishi0x01/b21195c7fd75a191c0cd subsets_leq_k.py %}

In order to determine the next mask, we check whether the current mask has less than \\(K\\) 1 bits set. 
In that case, we know that by adding 1 at maximum one more bit will be set to 1. 
Otherwise we determine the mask's lowest set bit and add it to its value.
{: .text-justify}

{% include tags/hint-start.html %}
In this case we got \\(\sum\limits_{i=0}^K {N \choose i}\\) subsets.
{% include tags/hint-end.html %}


[wiki-powerset]: http://en.wikipedia.org/wiki/Power_set
