---
layout: post
title: "OPRs and Least Squares Approximation, Geometrically"
date: 2017-10-08 21:30:56
categories: opr, stat, frc, linalg
---
<script src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.0/MathJax.js?config=TeX-AMS-MML_HTMLorMML" type="text/javascript"></script>

 Recently posted on [The Blue Alliance](https://blog.thebluealliance.com/2017/10/05/the-math-behind-opr-an-introduction/) blog was a fantastic post by Eugene, outlining the math behind OPRs through the use of the Least Squares approximation to solve an overdetermined system of equations.
In this post, I'll be going over the specifics of the normal equation $$ A^T A  x = A^T b $$ and give an understanding of how
it works.


<!-- excerpt -->

_Note: This post assumes basic familiarity with matricies and how they relate to systems of equations. It is recommended you read the Blue Alliance blog post prior to this one._


## OPRs and Overdetermined Systems
When calculating OPR, we will have many different kinds of equations. As mentioned by Eugene in TBA's Blog post, we can represent OPRs with match outcomes in the following way,
where $$[a, b, c, d]$$ are the OPRs of each alliance member.
\\[ 1a+1b+0c+0d=10 \\] 
\\[ 1a+0b+1c+0d=13 \\] 
\\[ 0a+1b+1c+0d=07 \\]
\\[ 1a+0b+0c+1d = 15 \\]
\\[ 0a+1b+0c+1d = 10 \\]
\\[ Ax = b \\]
\\[ \begin{bmatrix} 1&1&0&0 \\\\ 1&0&1&0 \\\\ 0&1&1&0 \\\\ 1&0&0&1 \\\\ 0&1&0&1 \end{bmatrix} x = \begin{bmatrix} 10\\\\13\\\\07\\\\15\\\\10 \end{bmatrix}\\]
(Here, Vector $$x$$ contains OPRs $$a$$ thru $$d$$)

Note that we can't solve this at the moment, since the number of rows is greater than the number of columns (not square), and as such we can't find the inverse $$A^{-1}$$. We call this system **overdetermined**, and as such the solutions are 
inconsistent, meaning we can't possibly satisfy all equations at once.

To overcome this, we need to introduce the concept of 'error'. If we pick values for $$a$$ thru $$d$$ with regards to the first 4 rows of the matrix, and then plug those values into
the last row of the matrix, there will be some error in our solution. In order to solve our equation, we need to make our "best guess", while reducing the error as low
as possible.

## Least Squares, Geometrically
In order to reduce the error in our guess, we're going to use the Least Squares approximation method, which is a form of [linear regression](https://en.wikipedia.org/wiki/Linear_regression). If you've ever
used the 'line of best fit' function, this is likely what powers it.

Here, we're going to look into what least squares _is_, geometrically. First, we must understand **linear independence**.
[Linear Independence](https://en.wikipedia.org/wiki/Linear_independence) is when a group of Vectors is perfectly expressed in comparison to its rank. In short, this means the _minimum number of dimensions_ needed to express a space where Vectors can exist.
To demonstrate this simply, the 2D XY space can be fully expressed by $$(0, 1)$$ and $$(1, 0)$$, and is therefore linearly independent. If we add another vector $$(1, 1)$$ into the mix, we get 3 "basis" vectors
for 2D space, meaning we must eliminate one of them to reach linear independence.

Now, we must consider **column space**. Column space is simply an $$n$$-dimensional space where all column vectors of the Matrix $$A$$ live, where $$n$$ is the rank of the Matrix such that the Matrix is
linearly independent. For example:
\\[ \begin{bmatrix} a & b \\\\ c & d \end{bmatrix} = \\{ \begin{bmatrix} a \\\\ c \end{bmatrix}, \begin{bmatrix} b \\\\ d \end{bmatrix} \\} \\] 

For now, we don't need to know what $$n$$ is, but we do need to know that the vectors of all columns of the Matrix exist in this space. In the below diagram, the column space of
some 2D matrix is expressed as a plane.

![Least Squares Diagram]({{ "/ta/img/LeastSquaresDiagram.jpg" }})

In this diagram, our 'ideal' solution exists within the plane (the point $$A\underset{\sim}{x}$$). Since we know our solution isn't perfect, there will be some error when it comes
to apply this solution to our equation to find the values of $$b$$ (the match outcomes). This error can be expressed by direction vector $$\underset{\sim}{e}$$, and is orthogonal (perpendicular)
to the plane (that is, the $$(n+1)^{th}$$ dimension). The reason this sits orthogonal is that it must enter a higher dimension, as it does not exist in our column space, but instead _slightly_ out of it. With this
in mind, we can express the position vector $$\underset{\sim}{b}$$ as:

\\[ \underset{\sim}{b} = A\underset{\sim}{x} + \underset{\sim}{e} \\]

And thus, the error as:
\\[\underset{\sim}{e} = \underset{\sim}{b} - A\underset{\sim}{x} \\]

It should be noted here that the term "Least Squared Error" is in fact the minimum distance of $$\underset{\sim}{b}$$ from the plane. Since we know the minimum distance between a point and the
plane is the magnitude of the vector orthogonal to the plane that meets the point, the Least Squared Error is the magnitude of $$\underset{\sim}{e}$$, i.e:
\\[ ||\underset{\sim}{e}|| = ||\underset{\sim}{b} - A\underset{\sim}{x}|| \\]

Since the error vector is orthogonal to the column space, we know that it must also be othogonal to every column in $$A$$, as otherwise, the error vector would exist within the column space.
We know from basic linear algebra that two vectors are orthogonal if their dot product is equal to 0 ($$a \cdot b = 0$$). As we're checking for orthogonality between our error vector $$\underset{\sim}{e}$$ and
all column vectors of $$A$$, we can check for all of them at once by transposing $$A$$ such that the columns become rows, and multiplying it by our error vector. Equating this to 0 enforces orthogonality.
\\[ A^T \underset{\sim}{e} = 0 \\]
\\[ A^T(\underset{\sim}{b} - A\underset{\sim}{x}) = 0 \\]
\\[ A^T\underset{\sim}{b} - A^T A\underset{\sim}{x} = 0 \\]
\\[ A^T A\underset{\sim}{x} = A^T\underset{\sim}{b} \\]
\\[ \underset{\sim}{x} = (A^T A)^{-1} A^T\underset{\sim}{b} \\]

This is known as the **pseudoinverse**, and is denoted as $$A^+ = (A^T A)^{-1} A^T$$. The [pseudoinverse](https://en.wikipedia.org/wiki/Moore%E2%80%93Penrose_pseudoinverse) (also known as the generalized inverse, Moore-Penrose inverse and others)
is used as a stand-in for $$A^{-1}$$ for matricies that aren't square (i.e. overdetermined systems), and is used to minimize the magnitude of the error vector (i.e. find the Least Squared Error solution).

We can apply this pseudoinverse to our original data, using the following:
\\[ x = A^{-1}b \\]
\\[ x = A^+b \\]
\\[ x = (A^T A)^{-1} A^T b \\]
\\[ or \\]
\\[ A^T A  x = A^T b \\]
This is identical to what we determined geometrically, and will provide the best fitting solution of $$x$$ values to minimize the error, giving the 'best guess' at what those values should be. In our case, this is
what gives our OPR.

### Efficiency and Cholesky Decomposition
It should be noted that while the use of pseudoinverses is practical for smaller datasets (such as OPRs for a single event), it becomes very expensive in both time and storage to compute the pseudoinverse for much larger
datasets. When speed and efficiency is a necessity for the larger datasets, it's common to instead use [Cholesky Decomposition](https://en.wikipedia.org/wiki/Cholesky_decomposition) in order to solve the normal equation $$ A^T A  x = A^T b $$.

While most of this reading is left up to the reader, Cholesky Decomposition states that for some real, symmetric, positive-definite matrix, $$A = LL^T$$, where $$L$$ is a lower triangular matrix with real positive diagonals, as shown below:
\\[ L = \begin{bmatrix} 1 & 0 & 0 \\\\ 4 & 6 & 0 \\\\ 5 & 6 & 1 \end{bmatrix} \\]

Since $$A^T A$$ is a real, symmetric and positive-definite matrix, we can rewrite our normal equation like so:
\\[ A^T A  x = A^T b \\]
\\[ A^T A = L L^T \\]
\\[ \therefore L L^T x = A^T b \\]
\\[ L y = A^T b \\]
\\[ L^T x = y \\]

$$y$$ can be solved for through [forward-substitution](https://en.wikipedia.org/wiki/Triangular_matrix#Forward_and_back_substitution), since $$L$$ is known to be lower triangular. Likewise, $$x$$ can then be solved for through [back-substitution](https://en.wikipedia.org/wiki/Triangular_matrix#Forward_and_back_substitution), both of which are relatively inexpensive operations.

Thanks to Ether for the help in this particular section of the post. 

## Final Notes
The same logic behind pseudoinverses can be applied to other elements of scoring in FRC other than just OPRs. 
Let's take a look at a 2D dataset, that is, $$(x_m, y_m)$$. This could be something like High Fuel Scored vs OPR, or whatever stat you want to measure.

\\[ (x_1,y_1), (x_2, y_2) ... (x_m, y_m) \\]

Given these points, we can determine a trend curve, a polynomial of degree $$n$$, i.e:
\\[ y = a_0x_1^0 + a_1x_1^1 + a_2x_1^2 + ... + a_nx_1^n \\]
\\[ y = a_0x_2^0 + a_1x_2^1 + a_2x_2^2 + ... + a_nx_2^n \\]
\\[ \vdots \\]
\\[ y = a_0x_m^0 + a_1x_m^1 + a_2x_m^2 + ... + a_nx_m^n \\]
Note $$x_m^0 = 1$$ and $$x_m^1 = x_m$$

Since we're trying to hunt down the $$a$$ values in order to solve for the polynomial equation, we can assign the following equation:
\\[ \begin{bmatrix} 
x_1^0 & x_1^1 & x_1^2 & ... & x_1^n \\\\ x_2^0 & x_2^1 & x_2^2 & ... & x_2^n \\\\ \vdots & \vdots & \vdots & \ddots & \vdots \\\\ x_m^0 & x_m^1 & x_m^2 & ... & x_m^n 
\end{bmatrix}
\begin{bmatrix}
a_0 \\\\ a_1 \\\\ \vdots \\\\ a_n
\end{bmatrix}
=
\begin{bmatrix}
y_1 \\\\ y_2 \\\\ \vdots \\\\ y_m
\end{bmatrix} \\]
Note $$x_m^0 = 1$$ and $$x_m^1 = x_m$$

Using our knowledge of pseudoinverses, we can apply the following equation to find the Vector of $$a$$ values
\\[ \begin{bmatrix} a_0 \\\\ a_1 \\\\ \vdots \\\\ a_n \end{bmatrix} = (M^T M)^{-1} M^T \begin{bmatrix} y_1 \\\\ y_2 \\\\ \vdots \\\\ y_m \end{bmatrix} \\]

You can use this knowledge to generate trend lines for your data, or for applying OPR to different datasets. All of this can be used to broaden your range of data for analysis, 
which is a great quality to have. Never look at one set of data on its own, look at a range of data before making deductions.
